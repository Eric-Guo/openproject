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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe "DDS external shares", :skip_csrf, type: :rails_request do
  let(:project) { create(:project, enabled_module_names: %w[work_package_tracking storages]) }
  let(:storage) { create(:edoc_dds_storage) }
  let(:project_storage) { create(:project_storage, project:, storage:) }
  let(:work_package) { create(:work_package, project:) }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:permissions) { %i[view_work_packages view_file_links manage_file_links] }
  let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let!(:uploaded) do
    create(:file_link, container: work_package, storage:, origin_id: "file:11",
                       origin_location_name: "工作包##{work_package.id}")
  end
  let!(:linked) do
    create(:file_link, container: work_package, storage:, origin_id: "file:22", origin_location_name: "Project docs")
  end
  let!(:folder) { create(:file_link, container: work_package, storage:, origin_id: "folder:33") }

  before do
    login_as(user)
    allow(Edoc::Config).to receive_messages(host: storage.host, token: "test-token")
    allow(Edoc::Folders).to receive(:create).and_return({ folder_id: 999 })
    allow(Edoc::Folders).to receive(:remove)
    allow(Edoc::Documents).to receive(:copy)
    allow(Edoc::FolderPublishes).to receive(:create).and_return("share-code")
  end

  it "renders selectable uploaded and linked files and the three expiry options" do
    get new_storage_external_share_path(project_storage.id), params: { work_package_id: work_package.id }, headers: headers

    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML.fragment(response.body)
    expect(html.css('input[name="file_link_ids[]"]').pluck("value")).to contain_exactly(uploaded.id.to_s, linked.id.to_s)
    expect(html.css('select[name="expiration"] option').pluck("value")).to eq(%w[day week month])
  end

  it "returns the second dialog step with a copyable link after creating the snapshot" do
    post storage_external_shares_path(project_storage.id),
         params: { work_package_id: work_package.id, file_link_ids: [uploaded.id, linked.id], expiration: "day" },
         headers: headers

    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML.fragment(response.body)
    expect(html.at_css('input[name="share_url"]')["value"]).to eq("#{storage.host}/outpublish.html?code=share-code#view")
    expect(html.at_css("clipboard-copy")["value"]).to include("share-code")
    expect(html.css('input[name="file_link_ids[]"]')).to be_empty
  end

  it "keeps the selection and expiry when DDS fails" do
    allow(Edoc::FolderPublishes).to receive(:create).and_raise(Edoc::Error.new("DDS failed"))
    post storage_external_shares_path(project_storage.id),
         params: { work_package_id: work_package.id, file_link_ids: [linked.id], expiration: "month" }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    html = Nokogiri::HTML.fragment(response.body)
    expect(html.css('input[name="file_link_ids[]"][checked]').pluck("value")).to eq([linked.id.to_s])
    expect(html.at_css('select[name="expiration"] option[selected]')["value"]).to eq("month")
    expect(html.at_css('[role="alert"]')).to be_present
  end

  it "rejects empty selection without creating a DDS folder" do
    post storage_external_shares_path(project_storage.id), params: { work_package_id: work_package.id, expiration: "day" },
                                                           headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
    expect(Edoc::Folders).not_to have_received(:create)
  end

  context "without sharing permission" do
    let(:permissions) { %i[view_work_packages view_file_links] }

    it "denies both dialog access and creation" do
      get new_storage_external_share_path(project_storage.id), params: { work_package_id: work_package.id }, headers: headers
      expect(response).to have_http_status(:forbidden)
      post storage_external_shares_path(project_storage.id),
           params: { work_package_id: work_package.id, file_link_ids: [linked.id], expiration: "day" }, headers: headers
      expect(response).to have_http_status(:forbidden)
      expect(Edoc::Folders).not_to have_received(:create)
    end
  end

  it "hides a project storage belonging to another project" do
    other = create(:project_storage, storage:)
    get new_storage_external_share_path(other.id), params: { work_package_id: work_package.id }, headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it "advertises the dialog only when the user can manage file links" do
    representer = API::V3::ProjectStorages::ProjectStorageRepresenter.new(project_storage, current_user: user)
    expect(representer.to_hash.dig("_links", "createExternalShare",
                                   "href")).to eq(new_storage_external_share_path(project_storage.id))
  end
end
