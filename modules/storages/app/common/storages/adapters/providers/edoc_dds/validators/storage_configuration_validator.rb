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
        module Validators
          class StorageConfigurationValidator < HealthReports::ValidatorGroup
            def self.key = :base_configuration

            private

            def validate
              register_checks :storage_configured, :diagnostic_request

              storage_configuration_status
              diagnostic_request
            end

            def storage_configuration_status
              if subject.configured?
                pass_check(:storage_configured)
              else
                fail_check(:storage_configured, :not_configured)
              end
            end

            def diagnostic_request
              if files_query.success?
                pass_check(:diagnostic_request)
              else
                fail_check(:diagnostic_request, :unknown_error)
              end
            end

            def files_query
              @files_query ||= Input::Files.build(folder: "/").bind do |input_data|
                Registry["#{subject}.queries.files"].call(storage: subject, auth_strategy:, input_data:)
              end
            end

            def auth_strategy
              Registry["#{subject}.authentication.userless"].call
            end
          end
        end
      end
    end
  end
end
