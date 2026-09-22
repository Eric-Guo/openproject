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

RSpec.describe API::V3::FileLinks::FileLinksOpenAPI, :webmock do
  let(:user) { create(:admin) }
  let(:storage) { create(:edoc_dds_storage) }
  let(:work_package) { create(:work_package) }
  let!(:project_storage) { create(:project_storage, project: work_package.project, storage:) }
  let(:file_link) { create(:file_link, storage:, container: work_package, origin_id: "file:41064621") }
  let(:path) { "/api/v3/file_links/#{file_link.id}/open" }
  let(:publish_code) { "preview+/code" }

  before do
    login_as user
    stub_request(:get, "https://dds.example.com/api/services/File/GetFileInfoById")
      .with(query: { token: storage.token, fileId: "41064621" })
      .to_return(status: 200, body: { result: 0, data: { fileName: "plan.pdf", parentFolderId: 13592019 } }.to_json)
    stub_request(:post, "https://dds.example.com/WebCore")
      .with(body: hash_including(module: "PublishManager", fun: "CreateFolderPublish",
                                 token: storage.token, folderIdList: "13592019"))
      .to_return(status: 200, body: { code: publish_code }.to_json)
  end

  it "redirects straight to the published DDS preview with a two-hour expiry" do
    freeze_time do
      get path

      expect(last_response).to have_http_status(:see_other)
      expect(last_response.location)
        .to eq("https://dds.example.com/preview.html?fileid=41064621&ispublish=true&code=preview%2B%2Fcode")
      expect(WebMock).to have_requested(:post, "https://dds.example.com/WebCore")
        .with(body: hash_including(endTime: 2.hours.from_now.strftime("%Y-%m-%d %H:%M:%S")))
    end
  end

  it "does not redirect when DDS publishing fails" do
    stub_request(:post, "https://dds.example.com/WebCore")
      .to_return(status: 200, body: { errorCode: 1, message: "Publishing failed" }.to_json)

    get path

    expect(last_response).to have_http_status(:internal_server_error)
    expect(last_response.location).to be_nil
  end

  it "does not publish files the current user cannot view" do
    login_as create(:user)

    get path

    expect(last_response).to have_http_status(:not_found)
    expect(WebMock).not_to have_requested(:post, "https://dds.example.com/WebCore")
    expect(WebMock).not_to have_requested(:get, "https://dds.example.com/api/services/File/GetFileInfoById")
  end
end
