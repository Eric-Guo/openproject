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
          class OpenFileLinkQuery < Base
            def call(auth_strategy:, input_data:)
              Authentication[auth_strategy].call(storage: @storage) do
                Success(open_url(input_data))
              end
            rescue Client::Error => e
              wrap_client_error(e)
            end

            private

            def open_url(input_data) # rubocop:disable Metrics/AbcSize
              if input_data.file_id.to_s.delete_prefix("/").start_with?("folder:")
                client.folder_url(folder_identifier(input_data.file_id))
              elsif input_data.open_location
                file = client.file_info(file_identifier(input_data.file_id))
                client.folder_url(file[:parent_folder_id])
              elsif input_data.file_link_id
                client.annotator_url(input_data.file_link_id)
              else
                client.preview_url(file_identifier(input_data.file_id))
              end
            end
          end
        end
      end
    end
  end
end
