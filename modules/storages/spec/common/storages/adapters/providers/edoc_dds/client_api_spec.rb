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

require "spec_helper"
require_module_spec_helper

module Storages
  module Adapters
    module Providers
      module EdocDds
        RSpec.describe Client, :webmock do
          let(:storage) { build_stubbed(:edoc_dds_storage) }
          let(:client) { described_class.new(storage) }

          def stub_get(path, params, body)
            stub_request(:get, "#{storage.host}/api/services/#{path}")
              .with(query: { token: storage.token }.merge(params))
              .to_return_json(body:)
          end

          def stub_file_page(page, files:, total:)
            stub_get("File/GetChildFilePageListByFolderId", { folderId: "100", pageIndex: page, pageSize: 100 },
                     { Result: 0, Code: 0, Files: files, TotalCount: total })
          end

          def file_item(id)
            { FileId: id, FileName: "设计 #{id}.pdf", FileExtName: ".pdf", FileLastSize: id * 10 }
          end

          describe "#list_files" do
            it "collects every page and retains the adapter's file shape" do
              first_page = stub_file_page(1, files: (1..100).map { |id| file_item(id) }, total: 101)
              last_page = stub_file_page(2, files: [file_item(101)], total: 101)

              files = client.list_files("100")

              expect(files.pluck(:file_id)).to eq((1..101).to_a)
              expect(files.last).to eq(file_id: 101, file_name: "设计 101.pdf", ext_name: ".pdf", size: 1010)
              expect(first_page).to have_been_requested.once
              expect(last_page).to have_been_requested.once
            end

            it "stops on a full final page without requesting another page" do
              stub_file_page(1, files: (1..100).map { |id| file_item(id) }, total: 100)

              expect(client.list_files("100").size).to eq(100)
            end

            it "returns an empty list for an empty folder" do
              stub_file_page(1, files: [], total: 0)

              expect(client.list_files("100")).to eq([])
            end

            it "accepts the SDK's camelCase page response" do
              stub_get("File/GetChildFilePageListByFolderId", { folderId: "100", pageIndex: 1, pageSize: 100 },
                       { result: 0, code: 0, files: [{ fileId: 7, fileName: "a.pdf", fileExtName: ".pdf", fileLastSize: 20 }],
                         totalCount: 1 })

              expect(client.list_files("100")).to eq([{ file_id: 7, file_name: "a.pdf", ext_name: ".pdf", size: 20 }])
            end

            it "rejects a missing final page instead of returning an incomplete list" do
              stub_file_page(1, files: (1..100).map { |id| file_item(id) }, total: 101)
              stub_file_page(2, files: [], total: 101)

              expect { client.list_files("100") }.to raise_error(Client::Error, /empty page/)
            end

            it "propagates a later page failure" do
              stub_file_page(1, files: (1..100).map { |id| file_item(id) }, total: 101)
              stub_get("File/GetChildFilePageListByFolderId", { folderId: "100", pageIndex: 2, pageSize: 100 },
                       { Result: 0, Code: 601 })

              expect { client.list_files("100") }.to raise_error(Client::Error, /601/)
            end

            [nil, -1, "1"].each do |total|
              it "rejects an invalid total count of #{total.inspect}" do
                stub_file_page(1, files: [file_item(1)], total:)

                expect { client.list_files("100") }.to raise_error(Client::Error, /invalid file page/)
              end
            end

            it "rejects a missing file collection" do
              stub_file_page(1, files: nil, total: 0)

              expect { client.list_files("100") }.to raise_error(Client::Error, /invalid file page/)
            end
          end

          %i[camel pascal].each do |casing|
            context "with #{casing}Case response keys" do
              let(:response_casing) { casing == :camel ? :lower : :upper }

              def response_keys(data)
                data.deep_transform_keys { |key| key.to_s.camelize(response_casing) }
              end

              it "reads folders" do
                body = response_keys(result: 0, data: [{ folder_id: 101, folder_name: "设计" }])
                stub_get("Folder/GetChildrenFolders", { topFolderId: "100" }, body)

                expect(client.list_folders("100")).to eq([{ folder_id: 101, folder_name: "设计" }])
              end

              it "reads folder metadata" do
                data = { folder_id: 101, folder_name: "设计", folder_size: 20, child_file_count: 1,
                         creator_id: 2, creator_name: "Author", editor_id: 3, editor_name: "Editor",
                         create_time: "2026-09-20", modify_time: "2026-09-21", parent_folder_id: 100 }
                stub_get("Folder/GetFolderInfoById", { folderId: 101 }, response_keys(result: 0, data:))

                expect(client.folder_info(101)).to include(data)
              end

              it "reads file metadata without losing false permission values" do
                data = { file_id: 7, file_name: "设计.pdf", file_size: 20, parent_folder_id: 100,
                         file_ext_name: ".pdf", can_download: false, can_preview: true, can_delete_file: false }
                stub_get("File/GetFileInfoById", { fileId: 7 }, response_keys(result: 0, data:))

                expect(client.file_info(7)).to include(data)
              end
            end
          end

          describe "#create_folder" do
            [0, 806].each do |code|
              it "uses the SDK payload and accepts result #{code}" do
                request = stub_request(:post, "#{storage.host}/api/services/Folder/CreateFolder")
                  .with(body: { token: storage.token, parentFolderId: "100", name: "设计", folderCode: "", remark: "" }.to_json,
                        headers: { "Content-Type" => "application/json" })
                  .to_return_json(body: { Result: code, Data: { FolderId: 101, Name: "设计" } })

                expect(client.create_folder(parent_folder_id: "100", name: "设计"))
                  .to eq(folder_id: 101, folder_name: "设计")
                expect(request).to have_been_requested.once
              end
            end

            it "does not accept an error code alongside an accepted result" do
              stub_request(:post, "#{storage.host}/api/services/Folder/CreateFolder")
                .to_return_json(body: { result: 806, code: 601 })

              expect { client.create_folder(parent_folder_id: "100", name: "设计") }
                .to raise_error(Client::Error, /601/)
            end
          end

          %i[file folder].each do |type|
            describe "#remove_#{type}" do
              it "sends the complete synchronous deletion payload" do
                request = stub_request(:post, "#{storage.host}/api/services/Doc/RemoveFolderListAndFileList")
                  .with(body: { token: storage.token, fileIdList: type == :file ? [7] : [],
                                folderIdList: type == :folder ? [7] : [], filePathList: [], folderPathList: [],
                                async: false }.to_json,
                        headers: { "Content-Type" => "application/json" })
                  .to_return_json(body: { result: 0, data: "ok" })

                expect(client.public_send("remove_#{type}", 7)).to eq("ok")
                expect(request).to have_been_requested.once
              end
            end
          end

          describe "SDK errors" do
            [{ data: [] }, { Result: 601 }, { result: 0, code: 601 }, { result: "invalid" }, { result: false }].each do |body|
              it "rejects unsuccessful result #{body.inspect}" do
                stub_get("File/GetFileInfoById", { fileId: 7 }, body)

                expect { client.file_info(7) }.to raise_error(Client::Error)
              end
            end

            it "accepts a code-only success response" do
              stub_get("File/GetFileInfoById", { fileId: 7 }, { Code: 0, Data: { FileId: 7 } })

              expect(client.file_info(7)).to include(file_id: 7)
            end

            it "retains conflict mapping for duplicate files" do
              stub_get("File/GetFileInfoById", { fileId: 7 }, { Result: 610 })

              expect { client.file_info(7) }
                .to raise_error(Client::Error) { |error| expect(error.code).to eq(:conflict) }
            end

            ["[]", "null", "<html>secret-token</html>"].each do |body|
              it "rejects malformed JSON responses without exposing the body: #{body}" do
                stub_request(:get, "#{storage.host}/api/services/File/GetFileInfoById")
                  .with(query: { token: storage.token, fileId: 7 })
                  .to_return(body:)

                expect { client.file_info(7) }.to raise_error(Client::Error) do |error|
                  expect(error.message).not_to include("secret-token")
                  expect(error.payload).to be_nil
                end
              end
            end

            { 401 => :unauthorized, 403 => :forbidden, 404 => :not_found, 409 => :conflict, 500 => :error }.each do |status, code|
              it "maps HTTP #{status} without exposing the body" do
                stub_request(:get, "#{storage.host}/api/services/File/GetFileInfoById")
                  .with(query: { token: storage.token, fileId: 7 })
                  .to_return(status:, body: "secret-token")

                expect { client.file_info(7) }.to raise_error(Client::Error) do |error|
                  expect(error.code).to eq(code)
                  expect(error.message).not_to include("secret-token")
                  expect(error.payload).to be_nil
                end
              end
            end

            it "wraps timeouts without exposing the token" do
              request = stub_request(:get, "#{storage.host}/api/services/File/GetFileInfoById")
                .with(query: { token: storage.token, fileId: 7 }).to_timeout

              expect { client.file_info(7) }.to raise_error(Client::Error, "EDoc request timed out")
              expect(request).to have_been_requested.once
            end

            it "wraps connection failures without exposing the token" do
              stub_request(:get, "#{storage.host}/api/services/File/GetFileInfoById")
                .with(query: { token: storage.token, fileId: 7 }).to_raise(SocketError.new("secret-token"))

              expect { client.file_info(7) }.to raise_error(Client::Error, "EDoc connection failed")
            end

            it "sets SDK connection and IO timeouts and disables retries" do
              stub_get("File/GetFileInfoById", { fileId: 7 }, { result: 0, data: { fileId: 7 } })
              allow(Net::HTTP).to receive(:start).and_call_original

              client.file_info(7)

              expect(Net::HTTP).to have_received(:start).with("dds.example.com", 443,
                                                              use_ssl: true, open_timeout: 30, read_timeout: 30,
                                                              write_timeout: 30, max_retries: 0)
            end
          end

          describe "#download_url" do
            it "uses the reviewed legacy download parameters and region hash" do
              stub_request(:get, "#{storage.host}/downLoad/DownLoadCheck")
                .with(query: { token: storage.token, file_id: 7 })
                .to_return_json(body: { nResult: 0, RegionHash: "region+hash=" })

              uri = URI(client.download_url(7))

              expect(uri.path).to eq("/downLoad/index")
              expect(URI.decode_www_form(uri.query).to_h)
                .to eq("token" => storage.token, "file_id" => "7", "regionHash" => "region+hash=")
            end

            it "rejects an unsuccessful download check" do
              stub_request(:get, "#{storage.host}/downLoad/DownLoadCheck")
                .with(query: { token: storage.token, file_id: 7 })
                .to_return_json(body: { nResult: 5, message: "secret-token" })

              expect { client.download_url(7) }.to raise_error(Client::Error, "EDoc download check failed")
            end
          end
        end
      end
    end
  end
end
