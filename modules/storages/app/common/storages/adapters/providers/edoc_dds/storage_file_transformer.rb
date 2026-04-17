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
        class StorageFileTransformer
          def initialize(storage)
            @storage = storage
          end

          def transform_folder(folder)
            Results::StorageFile.build(
              id: folder_id(folder[:folder_id]),
              name: folder[:folder_name],
              mime_type: "application/x-op-directory",
              location: folder_location(folder[:folder_id]),
              permissions: %i[readable writeable]
            )
          end

          def transform_file(file)
            Results::StorageFile.build(
              id: file_id(file[:file_id]),
              name: file[:file_name],
              size: file[:size].to_i,
              mime_type: mime_type(file[:file_name], file[:ext_name]),
              location: "/file:#{file[:file_id]}",
              permissions: %i[readable writeable]
            )
          end

          def transform_folder_info(folder, status: "ok", status_code: 200) # rubocop:disable Metrics/AbcSize
            Results::StorageFileInfo.build(
              status:,
              status_code:,
              id: folder_id(folder[:folder_id]),
              name: folder[:folder_name],
              size: folder[:folder_size].to_i,
              mime_type: "application/x-op-directory",
              created_at: safe_time(folder[:create_time]),
              last_modified_at: safe_time(folder[:modify_time]),
              owner_id: folder[:creator_id].to_s,
              owner_name: folder[:creator_name],
              last_modified_by_id: folder[:editor_id].to_s,
              last_modified_by_name: folder[:editor_name],
              location: folder_location(folder[:folder_id]),
              permissions: %i[readable writeable]
            )
          end

          def transform_file_info(file, status: "ok", status_code: 200) # rubocop:disable Metrics/AbcSize
            Results::StorageFileInfo.build(
              status:,
              status_code:,
              id: file_id(file[:file_id]),
              name: file[:file_name],
              size: file[:file_size].to_i,
              mime_type: mime_type(file[:file_name], file[:file_ext_name]),
              created_at: safe_time(file[:file_create_time]),
              last_modified_at: safe_time(file[:file_modify_time]),
              owner_id: file[:creator_id].to_s,
              owner_name: file[:creator_name],
              last_modified_by_name: file[:editor_name],
              location: "/file:#{file[:file_id]}",
              permissions: %i[readable writeable]
            )
          end

          private

          def folder_location(id)
            id.to_s == @storage.root_folder_id.to_s ? "/" : "/folder:#{id}"
          end

          def folder_id(id)
            "folder:#{id}"
          end

          def file_id(id)
            "file:#{id}"
          end

          def mime_type(file_name, ext_name)
            MiniMime.lookup_by_filename(file_name)&.content_type ||
              MiniMime.lookup_by_filename("file.#{ext_name}")&.content_type ||
              "application/octet-stream"
          end

          def safe_time(value)
            return if value.blank?

            Time.zone.parse(value.to_s)
          rescue ArgumentError
            nil
          end
        end
      end
    end
  end
end
