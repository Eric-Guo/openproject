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
          class UploadLinkQuery < Base
            def call(auth_strategy:, input_data:)
              Authentication[auth_strategy].call(storage: @storage) do
                Results::UploadLink.build(
                  destination: upload_url(input_data),
                  method: :post
                )
              end
            end

            private

            def upload_url(input_data)
              path = API::V3::Utilities::PathHelper.url_for(:storage_upload, @storage.id)
              uri = URI(path)
              query = Rack::Utils.parse_nested_query(uri.query)
              query["project_id"] = input_data.project_id if input_data.respond_to?(:project_id) && input_data.project_id.present?
              uri.query = URI.encode_www_form(query) if query.present?
              uri.to_s
            end
          end
        end
      end
    end
  end
end
