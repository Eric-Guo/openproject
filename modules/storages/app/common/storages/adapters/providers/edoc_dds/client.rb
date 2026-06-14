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
          DEFAULT_ANNOTATOR_HOST = "https://annotator.thape.com.cn"
          ANNOTATOR_HOST_ENV = "TH_ANNOTATOR_HOST"
          MAX_CHUNK_SIZE = 5.megabytes

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

            Array(result[:data]).map do |item|
              {
                folder_id: item[:FolderId],
                folder_name: item[:FolderName]
              }
            end
          end

          def list_files(folder_id)
            result = get("/api/services/File/GetChildFileListByFolderId", token_param.merge(folderId: folder_id))
            assert_result!(result)

            Array(result[:data]).map do |item|
              {
                file_id: item[:FileId],
                file_name: item[:FileName],
                ext_name: item[:FileExtName],
                size: item[:FileLastSize] || item[:FileSize] || 0
              }
            end
          end

          def folder_info(folder_id) # rubocop:disable Metrics/AbcSize
            result = get("/api/services/Folder/GetFolderInfoById", token_param.merge(folderId: folder_id))
            assert_result!(result)

            data = result[:data]
            {
              child_file_count: data[:ChildFileCount],
              child_folder_count: data[:ChildFolderCount],
              create_time: data[:CreateTime],
              creator_id: data[:CreatorId],
              creator_name: data[:CreatorName],
              editor_id: data[:EditorId],
              editor_name: data[:EditorName],
              folder_id: data[:FolderId],
              folder_name: data[:FolderName],
              folder_path: data[:FolderPath],
              folder_size: data[:FolderSize],
              modify_time: data[:ModifyTime],
              parent_folder_id: data[:ParentFolderId],
              permission: data[:Permission]
            }
          end

          def file_info(file_id) # rubocop:disable Metrics/AbcSize
            result = get("/api/services/File/GetFileInfoById", token_param.merge(fileId: file_id))
            assert_result!(result)

            data = result[:data]
            {
              file_id: data[:FileId],
              file_name: data[:FileName],
              file_size: data[:FileSize],
              file_modify_time: data[:FileModifyTime],
              editor_name: data[:EditorName],
              file_create_time: data[:FileCreateTime],
              creator_id: data[:CreatorId],
              creator_name: data[:CreatorName],
              parent_folder_id: data[:ParentFolderId],
              file_path: data[:FilePath],
              file_ext_name: data[:FileExtName],
              can_preview: data[:CanPreview],
              can_download: data[:CanDownload],
              can_delete_file: data[:CanDeleteFile]
            }
          end

          def create_folder(parent_folder_id:, name:)
            result = post_json(
              "/api/services/Folder/CreateFolder",
              token_param(:Token).merge(
                ParentFolderId: parent_folder_id,
                Name: name,
                FolderCode: "",
                Remark: ""
              )
            )

            raise Error.new(result.inspect, code: :conflict, payload: result) unless [0, 806].include?(result[:result])

            {
              folder_id: result.dig(:data, :FolderId),
              folder_name: result.dig(:data, :Name)
            }
          end

          def remove_folder(folder_id)
            result = post_json(
              "/api/services/Doc/RemoveFolderListAndFileList",
              token_param.merge(FolderIdList: [folder_id])
            )
            assert_result!(result)
            result[:data]
          end

          def remove_file(file_id)
            result = post_json(
              "/api/services/Doc/RemoveFolderListAndFileList",
              token_param.merge(FileIdList: [file_id])
            )
            assert_result!(result)
            result[:data]
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
            build_url("preview.html", fileid: file_id)
          end

          def annotator_url(file_id)
            build_url("/", { file_id: }, host: annotator_host)
          end

          def folder_url(folder_id)
            build_url("/index.html", {}, fragment: "doc/enterprise/#{folder_id}")
          end

          def download_url(file_id)
            result = get("/downLoad/DownLoadCheck", token_param.merge(fileIds: file_id))
            raise Error.new(result.inspect, code: :error, payload: result) unless result[:nResult].to_i.zero?

            build_url("/downLoad/index", token_param.merge(file_id:, regionHash: result[:RegionHash]))
          end

          private

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
              file_id: result.dig(:data, :FileId),
              file_ver_id: result.dig(:data, :FileVerId),
              folder_id: result.dig(:data, :ParentFolderId),
              region_hash: result.dig(:data, :RegionHash),
              region_id: result.dig(:data, :RegionId),
              region_type: result.dig(:data, :RegionType),
              region_url: result.dig(:data, :RegionUrl),
              upload_id: SecureRandom.uuid,
              second_pass: truthy?(result[:secondPass])
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

            raise Error.new(result.inspect, code: :error, payload: result) if result[:status] == "Error"
            raise Error.new("Upload cancelled", code: :error, payload: result) if result[:status] == "Cancel"

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

          def perform_request(uri_or_url, request_or_class) # rubocop:disable Metrics/AbcSize
            uri = uri_or_url.is_a?(URI) ? uri_or_url : URI(uri_or_url)
            request = request_or_class.is_a?(Class) ? request_or_class.new(uri) : request_or_class

            response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
              http.request(request)
            end

            return response if response.is_a?(Net::HTTPSuccess)

            raise Error.new(response.body, code: http_error_code(response), payload: response)
          rescue SystemCallError, SocketError, OpenSSL::SSL::SSLError, Timeout::Error, URI::InvalidURIError => e
            raise Error.new(e.message, code: :error, payload: e)
          end

          def parse_response(response)
            JSON.parse(response.body.to_s).with_indifferent_access
          rescue JSON::ParserError => e
            raise Error.new(e.message, code: :error, payload: e)
          end

          def assert_result!(result)
            return if result[:result].to_i.zero?

            raise Error.new(result.inspect, code: error_code(result), payload: result)
          end

          def error_code(result)
            case result[:result].to_i
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

          def annotator_host
            configured_annotator_host.presence || ENV.fetch(ANNOTATOR_HOST_ENV, DEFAULT_ANNOTATOR_HOST)
          end

          def configured_annotator_host
            @storage.annotator_host if @storage.respond_to?(:annotator_host)
          end

          def token_param(key = :token)
            { key => @storage.token }
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
