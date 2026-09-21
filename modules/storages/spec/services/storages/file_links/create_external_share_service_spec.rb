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

RSpec.describe Storages::FileLinks::CreateExternalShareService do
  include ActiveSupport::Testing::TimeHelpers

  let(:storage) { create(:edoc_dds_storage) }
  let(:project) { create(:project, enabled_module_names: %w[work_package_tracking storages]) }
  let(:project_storage) { create(:project_storage, project:, storage:) }
  let(:work_package) { create(:work_package, project:) }
  let(:user) { create(:admin) }
  let(:uploaded) do
    create(:file_link, container: work_package, storage:, origin_id: "file:11",
                       origin_location_name: "工作包##{work_package.id}")
  end
  let(:linked) do
    create(:file_link, container: work_package, storage:, origin_id: "file:22", origin_location_name: "Project docs")
  end
  let(:ids) { [uploaded.id.to_s, linked.id.to_s] }
  let(:expiration) { "week" }
  let(:service) { described_class.new(user:, work_package:, project_storage:) }

  subject(:result) { service.call(file_link_ids: ids, expiration:) }

  before do
    allow(Edoc::Config).to receive_messages(host: storage.host, token: "test-token")
    allow(Edoc::Folders).to receive(:create).and_return({ folder_id: 999 })
    allow(Edoc::Folders).to receive(:remove)
    allow(Edoc::Documents).to receive(:copy)
    allow(Edoc::FolderPublishes).to receive(:create).and_return("share-code")
    allow(Edoc::FolderPublishes).to receive(:url).with("share-code").and_return("https://dds.example.com/outpublish.html?code=share-code#view")
  end

  it "copies both uploaded and linked files and publishes only the snapshot folder" do
    travel_to Time.zone.local(2026, 1, 31, 10) do
      expect(result).to be_success
      expect(Edoc::Documents).to have_received(:copy).with(target_folder_id: 999, file_ids: ["11"])
      expect(Edoc::Documents).to have_received(:copy).with(target_folder_id: 999, file_ids: ["22"])
      expect(Edoc::FolderPublishes).to have_received(:create).with(
        [999], name: anything, end_time: "2026-02-07 10:00:00", auth_type: 1, can_download: true
      )
      expect(result.result).to include(url: "https://dds.example.com/outpublish.html?code=share-code#view",
                                       expires_at: Time.zone.local(2026, 2, 7, 10))
      expect(uploaded.reload.origin_id).to eq("file:11")
      expect(linked.reload.origin_id).to eq("file:22")
      expect(Edoc::Folders).not_to have_received(:remove)
    end
  end

  { "day" => "2026-02-01 10:00:00", "month" => "2026-02-28 10:00:00" }.each do |duration, expected|
    it "expires after a calendar #{duration}" do
      travel_to Time.zone.local(2026, 1, 31, 10) do
        expect(service.call(file_link_ids: ids, expiration: duration)).to be_success
        expect(Edoc::FolderPublishes).to have_received(:create).with([999], hash_including(end_time: expected))
      end
    end
  end

  shared_examples "an invalid share" do
    it "rejects the request before modifying DDS" do
      expect(result).not_to be_success
      expect(Edoc::Folders).not_to have_received(:create)
      expect(Edoc::Documents).not_to have_received(:copy)
      expect(Edoc::FolderPublishes).not_to have_received(:create)
    end
  end

  context "with no files" do
    let(:ids) { [] }

    it_behaves_like "an invalid share"
  end

  context "with an invalid expiry" do
    let(:expiration) { "forever" }

    it_behaves_like "an invalid share"
  end

  context "with a forged ID" do
    let(:ids) { ["#{uploaded.id}invalid"] }

    it_behaves_like "an invalid share"
  end

  context "with a file from another work package" do
    let(:linked) { create(:file_link, storage:, origin_id: "file:22") }

    it_behaves_like "an invalid share"
  end

  context "with a file from another storage" do
    let(:linked) { create(:file_link, container: work_package, origin_id: "file:22") }

    it_behaves_like "an invalid share"
  end

  context "with a folder" do
    let(:linked) { create(:file_link, container: work_package, storage:, origin_id: "folder:22") }

    it_behaves_like "an invalid share"
  end

  context "without manage_file_links permission" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages view_file_links] }) }

    it_behaves_like "an invalid share"
  end

  context "with a DDS host mismatch" do
    before { allow(Edoc::Config).to receive(:host).and_return("https://other.example.com") }

    it_behaves_like "an invalid share"
  end

  it "keeps same-named files in separate snapshot subfolders" do
    linked.update!(origin_name: uploaded.origin_name)
    allow(Edoc::Folders).to receive(:create).with(parent_folder_id: 999, name: uploaded.id.to_s).and_return({ folder_id: 1000 })
    allow(Edoc::Folders).to receive(:create).with(parent_folder_id: 999, name: linked.id.to_s).and_return({ folder_id: 1001 })

    expect(result).to be_success
    expect(Edoc::Documents).to have_received(:copy).with(target_folder_id: 1000, file_ids: ["11"])
    expect(Edoc::Documents).to have_received(:copy).with(target_folder_id: 1001, file_ids: ["22"])
  end

  it "does not copy repeated selections twice" do
    expect(service.call(file_link_ids: [uploaded.id.to_s, uploaded.id.to_s], expiration:)).to be_success
    expect(Edoc::Documents).to have_received(:copy).once
  end

  it "removes the new snapshot and does not publish if copying fails" do
    allow(Edoc::Documents).to receive(:copy).and_raise(Edoc::Error.new("DDS failed"))

    expect(result).not_to be_success
    expect(Edoc::Folders).to have_received(:remove).with(999)
    expect(Edoc::FolderPublishes).not_to have_received(:create)
  end

  it "returns an error and cleans up the snapshot if publishing fails" do
    allow(Edoc::FolderPublishes).to receive(:create).and_raise(Edoc::Error.new("DDS failed"))

    expect(result).not_to be_success
    expect(Edoc::Folders).to have_received(:remove).with(999)
  end
end
