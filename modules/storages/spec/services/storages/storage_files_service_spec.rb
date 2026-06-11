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
  RSpec.describe StorageFilesService do
    let(:user) { create(:user) }
    let(:storage) { create(:edoc_dds_storage, root_folder_id: "100") }
    let(:files_query) { class_double(Adapters::Providers::EdocDds::Queries::FilesQuery) }
    let(:create_folder_command) { class_double(Adapters::Providers::EdocDds::Commands::CreateFolderCommand) }

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
        id: "folder:450344",
        name: "工作包#450344",
        mime_type: "application/x-op-directory",
        location: "/folder:450344",
        permissions: %i[readable writeable]
      )
    end

    let(:root_files) do
      Adapters::Results::StorageFileCollection.new([work_package_folder], root_folder, [])
    end

    let(:work_package_folder_files) do
      Adapters::Results::StorageFileCollection.new([], work_package_folder, [root_folder])
    end

    before do
      Adapters::Registry.stub("edoc_dds.queries.files", files_query)
      Adapters::Registry.stub("edoc_dds.commands.create_folder", create_folder_command)
      allow(create_folder_command).to receive(:call)
    end

    it "opens an existing Edoc DDS work package folder directly" do
      allow(files_query).to receive(:call).and_return(Success(root_files), Success(work_package_folder_files))

      result = described_class.call(storage:, user:, folder: "/", work_package_id: 450344)

      expect(result).to be_success
      expect(result.result).to eq(work_package_folder_files)
      expect(files_query).to have_received(:call).with(
        storage:,
        auth_strategy: anything,
        input_data: Adapters::Input::Files.build(folder: "/").value!
      )
      expect(files_query).to have_received(:call).with(
        storage:,
        auth_strategy: anything,
        input_data: Adapters::Input::Files.build(folder: work_package_folder.location).value!
      )
      expect(create_folder_command).not_to have_received(:call)
    end

    it "creates a missing Edoc DDS work package folder before opening it" do
      root_files_without_work_package_folder = Adapters::Results::StorageFileCollection.new([], root_folder, [])
      allow(files_query).to receive(:call).and_return(
        Success(root_files_without_work_package_folder),
        Success(work_package_folder_files)
      )
      allow(create_folder_command).to receive(:call).and_return(Success(work_package_folder))

      result = described_class.call(storage:, user:, folder: "/", work_package_id: 450344)

      expect(result).to be_success
      expect(result.result).to eq(work_package_folder_files)
      expect(create_folder_command).to have_received(:call).with(
        storage:,
        auth_strategy: anything,
        input_data: Adapters::Input::CreateFolder.build(folder_name: "工作包#450344", parent_location: "/").value!
      )
      expect(files_query).to have_received(:call).with(
        storage:,
        auth_strategy: anything,
        input_data: Adapters::Input::Files.build(folder: work_package_folder.location).value!
      )
    end
  end
end
