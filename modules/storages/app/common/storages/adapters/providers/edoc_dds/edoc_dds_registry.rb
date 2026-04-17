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
  module Adapters
    module Providers
      module EdocDds
        EdocDdsRegistry = Dry::Core::Container::Namespace.new("edoc_dds") do
          namespace("authentication") do
            register(:userless, -> { Input::Strategy.build(key: :noop) })
            register(:user_bound, ->(user, storage = nil) { Input::Strategy.build(key: :noop, user:, storage:) })
          end

          namespace("commands") do
            register(:create_folder, Commands::CreateFolderCommand)
            register(:delete_folder, Commands::DeleteFolderCommand)
            register(:upload_file, Commands::UploadFileCommand)
          end

          namespace("components") do
            namespace("forms") do
              register(:general_information, Admin::Forms::GeneralInfoFormComponent)
            end

            register(:setup_wizard, StorageWizard)
            register(:general_information, Admin::GeneralInfoComponent)
          end

          namespace("contracts") do
            register(:storage, EdocDdsContract)
            register(:general_information, EdocDdsContract)
          end

          namespace("models") do
            register(:managed_folder_identifier, ManagedFolderIdentifier)
          end

          namespace("queries") do
            register(:download_link, Queries::DownloadLinkQuery)
            register(:file_info, Queries::FileInfoQuery)
            register(:files_info, Queries::FilesInfoQuery)
            register(:files, Queries::FilesQuery)
            register(:open_file_link, Queries::OpenFileLinkQuery)
            register(:open_storage, Queries::OpenStorageQuery)
            register(:upload_link, Queries::UploadLinkQuery)
            register(:user, Queries::UserQuery)
          end

          namespace("validators") do
            register(:connection, Validators::ConnectionValidator)
          end
        end
      end
    end
  end
end
