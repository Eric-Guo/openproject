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
        module Queries
          class FilesQuery < Base
            def call(auth_strategy:, input_data:)
              Authentication[auth_strategy].call(storage: @storage) do
                current_folder_id = folder_identifier(input_data.folder)
                folders = client.list_folders(current_folder_id)
                files = client.list_files(current_folder_id)

                Success(
                  unwrap_result(
                    Results::StorageFileCollection.build(
                      files: storage_files(folders, files),
                      parent: parent_folder(current_folder_id),
                      ancestors: ancestors(current_folder_id)
                    )
                  )
                )
              rescue Client::Error => e
                wrap_client_error(e)
              end
            end

            private

            def storage_files(folders, files)
              folders.map { |folder| unwrap_result(transformer.transform_folder(folder)) } +
                files.map { |file| unwrap_result(transformer.transform_file(file)) }
            end

            def parent_folder(current_folder_id)
              return root_folder if current_folder_id.to_s == @storage.root_folder_id.to_s

              info = client.folder_info(current_folder_id)
              unwrap_result(transformer.transform_folder(folder_id: info[:folder_id], folder_name: info[:folder_name]))
            end

            def ancestors(current_folder_id)
              current_folder_id.to_s == @storage.root_folder_id.to_s ? [] : [root_ancestor]
            end

            def transformer
              @transformer ||= StorageFileTransformer.new(@storage)
            end
          end
        end
      end
    end
  end
end
