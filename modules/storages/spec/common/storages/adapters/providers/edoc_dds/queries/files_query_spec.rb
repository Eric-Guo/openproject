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
          RSpec.describe FilesQuery, :webmock do
            let(:storage) { build_stubbed(:edoc_dds_storage) }
            let(:auth_strategy) { Registry["edoc_dds.authentication.userless"].call }
            let(:input_data) { Input::Files.build(folder: "/").value! }
            let(:last_page) do
              { result: 0, files: [{ fileId: 101, fileName: "设计.pdf", fileExtName: ".pdf", fileLastSize: 20 }],
                totalCount: 101 }
            end

            before do
              stub_request(:get, "#{storage.host}/api/services/Folder/GetChildrenFolders")
                .with(query: { token: storage.token, topFolderId: "100" })
                .to_return_json(body: { result: 0, data: [{ folderId: 200, folderName: "Plans" }] })
              stub_request(:get, "#{storage.host}/api/services/File/GetChildFilePageListByFolderId")
                .with(query: { token: storage.token, folderId: "100", pageIndex: 1, pageSize: 100 })
                .to_return_json(body: { result: 0,
                                        files: (1..100).map do |id|
                                          { fileId: id, fileName: "#{id}.txt", fileExtName: ".txt", fileLastSize: 10 }
                                        end,
                                        totalCount: 101 })
              stub_request(:get, "#{storage.host}/api/services/File/GetChildFilePageListByFolderId")
                .with(query: { token: storage.token, folderId: "100", pageIndex: 2, pageSize: 100 })
                .to_return_json(body: last_page)
            end

            it "returns folders and all file pages as storage files" do
              result = described_class.call(storage:, auth_strategy:, input_data:).value!

              expect(result.files.size).to eq(102)
              expect(result.files.first).to have_attributes(id: "folder:200", name: "Plans",
                                                            mime_type: "application/x-op-directory")
              expect(result.files.last).to have_attributes(id: "file:101", name: "设计.pdf", size: 20,
                                                           mime_type: "application/pdf", location: "/file:101")
              expect(result.parent).to have_attributes(id: "folder:100", location: "/")
              expect(result.ancestors).to eq([])
            end

            context "when a later page fails" do
              let(:last_page) { { Result: 0, Code: 601 } }

              it "returns an adapter failure instead of a partial collection" do
                result = described_class.call(storage:, auth_strategy:, input_data:)

                expect(result).to be_failure
                expect(result.failure.code).to eq(:error)
              end
            end
          end
        end
      end
    end
  end
end
