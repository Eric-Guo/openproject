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
        class Base
          include TaggedLogging
          include Dry::Monads::Result(SimpleError)

          def self.call(storage:, auth_strategy:, input_data:)
            new(storage).call(auth_strategy:, input_data:)
          end

          def initialize(storage)
            @storage = storage
          end

          private

          def client
            @client ||= Client.new(@storage)
          end

          def folder_identifier(value)
            raw = normalize_identifier(value)
            raw = @storage.root_folder_id if raw.blank? || raw == "/"
            raw.delete_prefix("folder:")
          end

          def file_identifier(value)
            normalize_identifier(value).delete_prefix("file:")
          end

          def folder_location(folder_id)
            folder_id.to_s == @storage.root_folder_id.to_s ? "/" : "/folder:#{folder_id}"
          end

          def folder_id(folder_id)
            "folder:#{folder_id}"
          end

          def file_id(file_id)
            "file:#{file_id}"
          end

          def root_folder
            Results::StorageFile.new(
              id: folder_id(@storage.root_folder_id),
              name: @storage.name,
              mime_type: "application/x-op-directory",
              location: "/",
              permissions: %i[readable writeable]
            )
          end

          def root_ancestor
            Results::StorageFileAncestor.new(name: @storage.name, location: "/")
          end

          def normalize_identifier(value)
            value.to_s.delete_prefix("/")
          end

          def wrap_client_error(error)
            Failure(SimpleError.new(source: self.class, code: error.code, payload: error.payload || error))
          end

          def unwrap_result(result)
            result.value_or do |failure|
              raise Client::Error.new(failure.inspect, code: :error, payload: failure)
            end
          end
        end
      end
    end
  end
end
