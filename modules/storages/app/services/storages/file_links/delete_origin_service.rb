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
  module FileLinks
    class DeleteOriginService < DeleteService
      private

      def after_validate(call)
        storage = model.storage
        return unsupported_storage(call) unless storage.provider_type_edoc_dds?

        strategy = auth_strategy(storage)
        file_info = origin_file_info(storage, strategy)
                      .value_or { |error| return add_error_to_call(call, error) }
        delete_input = delete_file_input(file_info)
                       .value_or { |error| return add_error_to_call(call, error, validation_error: true) }

        delete_origin_file(storage, strategy, delete_input)
          .value_or { |error| return add_error_to_call(call, error) }

        call
      end

      def unsupported_storage(call)
        call.errors.add(:base, :error_unauthorized)
        call.success = false
        call
      end

      def auth_strategy(storage)
        Adapters::Registry.resolve("#{storage}.authentication.user_bound").call(user, storage)
      end

      def origin_file_info(storage, auth_strategy)
        Adapters::Input::FileInfo.build(file_id: model.origin_id).bind do |input_data|
          Adapters::Registry.resolve("#{storage}.queries.file_info")
                            .call(storage:, auth_strategy:, input_data:)
        end
      end

      def delete_file_input(file_info)
        Adapters::Input::DeleteFile.build(file_id: model.origin_id, location: file_info.location)
      end

      def delete_origin_file(storage, auth_strategy, input_data)
        Adapters::Registry.resolve("#{storage}.commands.delete_file")
                          .call(storage:, auth_strategy:, input_data:)
      end

      def add_error_to_call(call, error, validation_error: false)
        if validation_error
          call.errors.add(:base, :invalid, **error.to_h)
        else
          call.errors.add(:base, error.code)
        end
        call.success = false
        call
      end
    end
  end
end
