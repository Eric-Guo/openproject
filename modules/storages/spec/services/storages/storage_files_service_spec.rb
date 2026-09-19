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
  RSpec.describe StorageFilesService, :webmock do
    let(:user) { create(:user) }
    let(:storage) { create(:edoc_dds_storage, root_folder_id: "100") }
    let(:files_query) { class_double(Adapters::Providers::EdocDds::Queries::FilesQuery) }
    let(:create_folder_result) { 0 }
    let(:create_folder_request) do
      stub_request(:post, "#{storage.uri}api/services/Folder/CreateFolder")
        .with(body: hash_including("ParentFolderId" => "11571310", "Name" => "工作包#450344"))
        .to_return_json(
          status: 200,
          body: { result: create_folder_result, data: { FolderId: "987654", Name: "工作包#450344" } }
        )
    end

    let(:root_folder) do
      Adapters::Results::StorageFile.new(
        id: "folder:100",
        name: "Edoc DDS",
        mime_type: "application/x-op-directory",
        location: "/",
        permissions: %i[readable writeable]
      )
    end

    let(:work_package_folder) do
      Adapters::Results::StorageFile.new(
        id: "folder:987654",
        name: "工作包#450344",
        mime_type: "application/x-op-directory",
        location: "/folder:987654",
        permissions: %i[readable writeable]
      )
    end

    let(:work_package_folder_files) do
      Adapters::Results::StorageFileCollection.new([], work_package_folder, [root_folder])
    end

    before do
      Adapters::Registry.stub("edoc_dds.queries.files", files_query)
      create_folder_request
      allow(files_query).to receive(:call)
        .with(
          storage:,
          auth_strategy: anything,
          input_data: Adapters::Input::Files.build(folder: work_package_folder.location).value!
        )
        .and_return(Success(work_package_folder_files))
    end

    around do |example|
      with_env("EDOC_WP_FOLDER" => "11571310") { example.run }
    end

    shared_examples "opening the returned work package folder" do
      it "fetches only the returned folder without listing the parent" do
        result = described_class.call(storage:, user:, folder: "/", work_package_id: 450344)

        expect(result).to be_success
        expect(result.result).to eq(work_package_folder_files)
        expect(create_folder_request).to have_been_requested.once
        expect(files_query).to have_received(:call).once.with(
          storage:,
          auth_strategy: anything,
          input_data: Adapters::Input::Files.build(folder: work_package_folder.location).value!
        )
      end
    end

    context "when DDS creates the work package folder" do
      it_behaves_like "opening the returned work package folder"
    end

    context "when the work package folder already exists" do
      let(:create_folder_result) { 806 }

      it_behaves_like "opening the returned work package folder"
    end

    context "when DDS rejects the folder creation" do
      let(:create_folder_result) { 1 }

      it "returns the failure without fetching files" do
        result = described_class.call(storage:, user:, folder: "/", work_package_id: 450344)

        expect(result).to be_failure
        expect(result.errors.symbols_for(:base)).to contain_exactly(:conflict)
        expect(files_query).not_to have_received(:call)
      end
    end
  end
end
