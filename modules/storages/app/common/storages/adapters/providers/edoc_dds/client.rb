# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "digest/md5"
require "net/http"
require "openssl"
require "securerandom"
require "tempfile"

module Storages
  module Adapters
    module Providers
      module EdocDds
        class Client
          MAX_CHUNK_SIZE = 5.megabytes
          FILE_PAGE_SIZE = 100
          REQUEST_TIMEOUT = 30

          class Error < StandardError
            attr_reader :code, :payload

            def initialize(message = nil, code: :error, payload: nil)
              super(message || code.to_s)
              @code = code
              @payload = payload
            end
          end

          def initialize(storage)
            @storage = storage
          end

          def list_folders(folder_id)
            result = get("/api/services/Folder/GetChildrenFolders", token_param.merge(topFolderId: folder_id))
            assert_result!(result)

            result.fetch(:data).map do |item|
              {
                folder_id: item[:folder_id],
                folder_name: item[:folder_name]
              }
            end
          end

          def list_files(folder_id)
            files = []
            page = 1

            loop do
              result = file_page(folder_id, page)
              files.concat(result[:files].map { |item| listed_file(item) })
              break if page * FILE_PAGE_SIZE >= result[:total_count]

              page += 1
            end

            files
          end

          def folder_info(folder_id)
            result = get("/api/services/Folder/GetFolderInfoById", token_param.merge(folderId: folder_id))
            assert_result!(result)

            result.fetch(:data).slice(:child_file_count, :child_folder_count, :create_time, :creator_id, :creator_name,
                                      :editor_id, :editor_name, :folder_id, :folder_name, :folder_path, :folder_size,
                                      :modify_time, :parent_folder_id, :permission)
          end

          def file_info(file_id)
            result = get("/api/services/File/GetFileInfoById", token_param.merge(fileId: file_id))
            assert_result!(result)

            result.fetch(:data).slice(:file_id, :file_name, :file_size, :file_modify_time, :editor_name,
                                      :file_create_time, :creator_id, :creator_name, :parent_folder_id,
                                      :file_path, :file_ext_name, :can_preview, :can_download, :can_delete_file)
          end

          def create_folder(parent_folder_id:, name:)
            result = post_json(
              "/api/services/Folder/CreateFolder",
              token_param.merge(
                parentFolderId: parent_folder_id,
                name:,
                folderCode: "",
                remark: ""
              )
            )

            assert_result!(result, success_codes: [0, 806])

            {
              folder_id: result.dig(:data, :folder_id),
              folder_name: result.dig(:data, :name)
            }
          end

          def remove_folder(folder_id)
            remove_documents(folder_ids: [folder_id])
          end

          def remove_file(file_id)
            remove_documents(file_ids: [file_id])
          end

          def upload(input_io, folder_id:, file_name:)
            with_file_path(input_io) do |path|
              start_result = start_upload(path, folder_id:, file_name:)
              file_result = {
                id: start_result[:file_id],
                name: start_result[:file_name],
                file_id: start_result[:file_id],
                file_ver_id: start_result[:file_ver_id],
                folder_id: start_result[:folder_id]
              }

              return file_result if start_result[:second_pass]

              chunk_file(path, start_result)
              file_result
            end
          end

          def preview_url(file_id)
            build_url("preview.html", { fileid: file_id })
          end

          def annotator_url(file_link_id)
            build_url("/th_work_packages/edoc_files/#{file_link_id}/annotation_document", {}, host: openproject_host)
          end

          def folder_url(folder_id)
            build_url("/index.html", {}, fragment: "doc/enterprise/#{folder_id}")
          end

          def download_url(file_id)
            result = get("/downLoad/DownLoadCheck", token_param.merge(file_id:))
            raise Error, "EDoc download check failed" unless result[:n_result] == 0

            build_url("/downLoad/index", token_param.merge(file_id:, regionHash: result[:region_hash]))
          end

          private

          def file_page(folder_id, page)
            result = get("/api/services/File/GetChildFilePageListByFolderId",
                         token_param.merge(folderId: folder_id, pageIndex: page, pageSize: FILE_PAGE_SIZE))
            assert_result!(result)
            validate_file_page!(result, page)
            result
          end

          def validate_file_page!(result, page)
            total = result[:total_count]
            unless total.is_a?(Integer) && total >= 0 && result[:files].is_a?(Array)
              raise Error, "EDoc returned an invalid file page"
            end

            if result[:files].empty? && (page - 1) * FILE_PAGE_SIZE < total
              raise Error, "EDoc returned an empty page before the end of the file list"
            end
          end

          def listed_file(item)
            {
              file_id: item[:file_id],
              file_name: item[:file_name],
              ext_name: item[:file_ext_name],
              size: item[:file_last_size] || item[:file_size] || 0
            }
          end

          def remove_documents(file_ids: [], folder_ids: [])
            result = post_json(
              "/api/services/Doc/RemoveFolderListAndFileList",
              token_param.merge(fileIdList: file_ids, folderIdList: folder_ids,
                                filePathList: [], folderPathList: [], async: false)
            )
            assert_result!(result)
            result[:data]
          end

          def start_upload(path, folder_id:, file_name:) # rubocop:disable Metrics/AbcSize
            file_size = File.size(path)
            raise Error.new("File size must be greater than 0", code: :unprocessable_entity) unless file_size.positive?

            md5 = calc_file_md5(path)
            result = post_form(
              "/WebCore?module=RegionDocOperationApi&fun=CheckAndCreateDocInfo",
              token_param.merge(
                folderId: folder_id,
                fileName: file_name,
                fileRemark: "",
                size: file_size,
                type: content_type(file_name),
                attachType: 0,
                fullPath: "",
                code: "",
                masterFileId: 0,
                fileId: 0,
                strategy: "majorUpgrade",
                fileModel: "UPLOAD",
                fileMd5: md5
              )
            )
            assert_result!(result)

            {
              md5:,
              file_size:,
              file_name:,
              file_id: result.dig(:data, :file_id),
              file_ver_id: result.dig(:data, :file_ver_id),
              folder_id: result.dig(:data, :parent_folder_id),
              region_hash: result.dig(:data, :region_hash),
              region_id: result.dig(:data, :region_id),
              region_type: result.dig(:data, :region_type),
              region_url: result.dig(:data, :region_url),
              upload_id: SecureRandom.uuid,
              second_pass: truthy?(result[:second_pass])
            }
          end

          def chunk_file(path, upload)
            chunks = (upload[:file_size].to_f / MAX_CHUNK_SIZE).ceil
            chunk = 0

            File.open(path, "rb") do |file|
              until file.eof?
                Tempfile.create("edoc-dds-upload-chunk") do |tempfile|
                  tempfile.binmode
                  bytes = file.read(MAX_CHUNK_SIZE)
                  tempfile.write(bytes)
                  tempfile.flush

                  chunk_upload(tempfile.path, upload:, chunks:, chunk:, block_size: bytes.bytesize)
                  chunk += 1
                end
              end
            end
          end

          def chunk_upload(path, upload:, chunks:, chunk:, block_size:) # rubocop:disable Metrics/AbcSize
            url = build_url(
              "/document/upload",
              token_param,
              host: upload[:region_type].to_i == 1 ? @storage.host : upload[:region_url]
            )

            result = post_multipart(
              url,
              uploadId: upload[:upload_id],
              regionHash: upload[:region_hash],
              regionId: upload[:region_id],
              fileName: upload[:file_name],
              fileMd5: upload[:md5],
              size: upload[:file_size],
              chunks:,
              chunk:,
              chunkSize: MAX_CHUNK_SIZE,
              blockSize: block_size,
              file: path
            )

            raise Error, "EDoc chunk upload failed" if result[:status] == "Error"
            raise Error, "Upload cancelled" if result[:status] == "Cancel"

            result
          end

          def get(path, params = {}, host: @storage.host)
            parse_response perform_request(build_url(path, params, host:), Net::HTTP::Get)
          end

          def post_json(path, payload, host: @storage.host)
            uri = build_uri(path, host:)
            request = Net::HTTP::Post.new(uri)
            request["Content-Type"] = "application/json"
            request.body = payload.to_json
            parse_response perform_request(uri, request)
          end

          def post_form(path, payload, host: @storage.host)
            uri = build_uri(path, host:)
            request = Net::HTTP::Post.new(uri)
            request.set_form_data(payload)
            parse_response perform_request(uri, request)
          end

          def post_multipart(url, payload)
            uri = URI(url)
            request = Net::HTTP::Post.new(uri)

            File.open(payload.fetch(:file), "rb") do |file|
              form_payload = payload.except(:file).transform_keys(&:to_s).transform_values(&:to_s).merge("file" => file)
              request.set_form(form_payload.to_a, "multipart/form-data")
              parse_response perform_request(uri, request)
            end
          end

          def perform_request(uri_or_url, request_or_class)
            uri = uri_or_url.is_a?(URI) ? uri_or_url : URI(uri_or_url)
            request = request_or_class.is_a?(Class) ? request_or_class.new(uri) : request_or_class

            response = Net::HTTP.start(uri.host, uri.port, **http_options(uri)) do |http|
              http.request(request)
            end

            return response if response.is_a?(Net::HTTPSuccess)

            raise Error.new("EDoc HTTP request failed (#{response.code})", code: http_error_code(response))
          rescue Timeout::Error
            raise Error, "EDoc request timed out"
          rescue SystemCallError, SocketError, OpenSSL::SSL::SSLError, IOError, URI::InvalidURIError
            raise Error, "EDoc connection failed"
          end

          def http_options(uri)
            options = { use_ssl: uri.scheme == "https" }
            return options unless uri.path.include?("/api/services/")

            options.merge(open_timeout: REQUEST_TIMEOUT, read_timeout: REQUEST_TIMEOUT,
                          write_timeout: REQUEST_TIMEOUT, max_retries: 0)
          end

          def parse_response(response)
            result = JSON.parse(response.body.to_s)
            raise Error, "EDoc returned an invalid response" unless result.is_a?(Hash)

            result.deep_transform_keys { |key| key.underscore.to_sym }
          rescue JSON::ParserError
            raise Error, "EDoc returned invalid JSON"
          end

          def assert_result!(result, success_codes: [0])
            codes = result.values_at(:result, :code).compact
            return if codes.any? && codes.all? { |code| success_codes.include?(code) }

            code = codes.find { |value| success_codes.exclude?(value) }
            raise Error.new("EDoc API request failed (result #{code.inspect})", code: error_code(code))
          end

          def error_code(code)
            case code
            when 610
              :conflict
            else
              :error
            end
          end

          def build_url(path, params = {}, fragment: nil, host: @storage.host)
            build_uri(path, params:, fragment:, host:).to_s
          end

          def build_uri(path, params: {}, fragment: nil, host: @storage.host)
            uri = URI.join(normalized_host(host), path.to_s.sub(%r{\A/+}, ""))
            query = Rack::Utils.parse_nested_query(uri.query).merge(params.stringify_keys)
            uri.query = URI.encode_www_form(query) if query.present?
            uri.fragment = fragment if fragment.present?
            uri
          end

          def normalized_host(host)
            "#{host.to_s.delete_suffix('/')}/"
          end

          def openproject_host
            "#{Setting.protocol}://#{Setting.host_name}"
          end

          def token_param
            { token: @storage.token }
          end

          def with_file_path(input_io)
            if input_io.respond_to?(:path) && File.exist?(input_io.path.to_s)
              yield input_io.path
            else
              input_io.rewind if input_io.respond_to?(:rewind)
              Tempfile.create("edoc-dds-upload") do |tempfile|
                tempfile.binmode
                IO.copy_stream(input_io, tempfile)
                tempfile.flush
                yield tempfile.path
              end
            end
          end

          def calc_file_md5(path)
            Digest::MD5.file(path).hexdigest
          end

          def content_type(file_name)
            MiniMime.lookup_by_filename(file_name)&.content_type || "application/octet-stream"
          end

          def truthy?(value)
            value == true || value.to_s == "true"
          end

          def http_error_code(response)
            case response.code.to_i
            when 401
              :unauthorized
            when 403
              :forbidden
            when 404
              :not_found
            when 409
              :conflict
            when 413
              :payload_too_large
            else
              :error
            end
          end
        end
      end
    end
  end
end
