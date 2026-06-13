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

module Storages
  class StorageFilesService < BaseService
    EDOC_DDS_WORK_PACKAGE_PARENT_FOLDER_ENV = "EDOC_WP_FOLDER"

    def self.call(storage:, user:, folder:, work_package_id: nil)
      new.call(storage:, user:, folder:, work_package_id:)
    end

    def call(user:, storage:, folder:, work_package_id: nil)
      with_tagged_logger do
        auth_strategy = strategy(storage, user)
        files = storage_files(storage:, auth_strategy:, folder:, work_package_id:).value_or do |error|
          return add_error(:base, error, options: { storage_name: storage.name, folder: })
        end

        @result.result = files
        @result
      end
    end

    private

    def strategy(storage, user)
      Adapters::Registry.resolve("#{storage}.authentication.user_bound").call(user, storage)
    end

    def request_folder(storage:, auth_strategy:, folder:, work_package_id:)
      return Success(folder) unless storage.provider_type_edoc_dds? && work_package_id.present? && folder == "/"

      edoc_dds_work_package_folder(storage:, auth_strategy:, work_package_id:).fmap(&:location)
    end

    def storage_files(storage:, auth_strategy:, folder:, work_package_id:)
      request_folder(storage:, auth_strategy:, folder:, work_package_id:).bind do |resolved_folder|
        info "Requesting all the files under folder #{resolved_folder} for #{storage.name}"
        fetch_files(storage:, auth_strategy:, folder: resolved_folder)
      end
    end

    def edoc_dds_work_package_folder(storage:, auth_strategy:, work_package_id:)
      folder_name = edoc_dds_work_package_folder_name(work_package_id)
      parent_location = edoc_dds_work_package_parent_location(storage)

      fetch_files(storage:, auth_strategy:, folder: parent_location).bind do |parent_files|
        existing_folder = find_folder(parent_files, folder_name)
        next Success(existing_folder) if existing_folder.present?

        create_edoc_dds_work_package_folder(storage:, auth_strategy:, folder_name:, parent_location:)
      end
    end

    def fetch_files(storage:, auth_strategy:, folder:)
      input_data = Adapters::Input::Files.build(folder:).value!
      Adapters::Registry
        .resolve("#{storage}.queries.files").call(storage:, auth_strategy:, input_data:)
    end

    def create_edoc_dds_work_package_folder(storage:, auth_strategy:, folder_name:, parent_location:)
      input_data = Adapters::Input::CreateFolder.build(folder_name:, parent_location:).value!
      Adapters::Registry["#{storage}.commands.create_folder"].call(storage:, auth_strategy:, input_data:)
    end

    def find_folder(files, folder_name)
      files.files.find { |file| file.folder? && file.name == folder_name }
    end

    def edoc_dds_work_package_folder_name(work_package_id)
      "工作包##{work_package_id}"
    end

    def edoc_dds_work_package_parent_location(storage)
      folder_id = ENV.fetch(EDOC_DDS_WORK_PACKAGE_PARENT_FOLDER_ENV)

      folder_id.to_s == storage.root_folder_id.to_s ? "/" : "/folder:#{folder_id}"
    end
  end
end
