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
        module Queries
          RSpec.describe OpenFileLinkQuery, :webmock do
            let(:storage) { build(:edoc_dds_storage) }
            let(:auth_strategy) { Registry["edoc_dds.authentication.userless"].call }

            it_behaves_like "storage adapter: query call signature", "open_file_link"

            context "with a file link" do
              let(:input_data) { Input::OpenFileLink.build(file_id: "file:306", file_link_id: 1113).value! }
              let(:open_file_link) { "https://dds.example.com/preview.html?fileid=306&ispublish=true&code=preview-code" }

              before do
                stub_request(:get, "https://dds.example.com/api/services/File/GetFileInfoById")
                  .with(query: { token: storage.token, fileId: "306" })
                  .to_return(status: 200, body: { result: 0, data: { fileName: "plan.pdf", parentFolderId: 200 } }.to_json)

                stub_request(:post, "https://dds.example.com/WebCore")
                  .with(body: hash_including(module: "PublishManager", fun: "CreateFolderPublish",
                                             token: storage.token, folderIdList: "200", outpublishName: "plan.pdf-PLM预览",
                                             outpublishAuthType: "1", canDownload: "true"))
                  .to_return(status: 200, body: { code: "preview-code" }.to_json)
              end

              it_behaves_like "adapter open_file_link_query: successful link response"

              context "when publishing fails" do
                before do
                  stub_request(:post, "https://dds.example.com/WebCore")
                    .to_return(status: 200, body: { errorCode: 1, message: "Publishing failed" }.to_json)
                end

                it "returns a storage error" do
                  result = described_class.call(storage:, auth_strategy:, input_data:)

                  expect(result).to be_failure
                  expect(result.failure.code).to eq(:error)
                end
              end

              context "with a slash-prefixed file id" do
                let(:input_data) { Input::OpenFileLink.build(file_id: "/file:306", file_link_id: 1113).value! }

                it_behaves_like "adapter open_file_link_query: successful link response"
              end

              context "when opening the containing folder" do
                let(:input_data) do
                  Input::OpenFileLink.build(file_id: "file:306", file_link_id: 1113, open_location: true).value!
                end
                let(:open_file_link) { "https://dds.example.com/index.html#doc/enterprise/200" }

                it_behaves_like "adapter open_file_link_query: successful link response"

                it "does not publish the folder" do
                  described_class.call(storage:, auth_strategy:, input_data:)

                  expect(WebMock).not_to have_requested(:post, "https://dds.example.com/WebCore")
                end
              end
            end

            context "with a file id without a file link" do
              let(:input_data) { Input::OpenFileLink.build(file_id: "file:306").value! }
              let(:open_file_link) { "https://dds.example.com/preview.html?fileid=306" }

              it_behaves_like "adapter open_file_link_query: successful link response"
            end

            context "with a folder link" do
              let(:input_data) { Input::OpenFileLink.build(file_id: "folder:200").value! }
              let(:open_file_link) { "https://dds.example.com/index.html#doc/enterprise/200" }

              it_behaves_like "adapter open_file_link_query: successful link response"
            end
          end
        end
      end
    end
  end
end
