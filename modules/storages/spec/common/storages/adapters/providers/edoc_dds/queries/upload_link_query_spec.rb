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
  module Adapters
    module Providers
      module EdocDds
        module Queries
          RSpec.describe UploadLinkQuery do
            let(:storage) { build_stubbed(:edoc_dds_storage, id: 1) }
            let(:auth_strategy) { Registry["edoc_dds.authentication.user_bound"].call(build_stubbed(:user), storage) }
            let(:input_data) do
              Input::UploadLink.build(folder_id: "folder:12339535",
                                      file_name: "G6ltS4qbYAANxtF.jpeg",
                                      project_id: 9277).value!
            end

            let(:upload_url) do
              "#{API::V3::Utilities::PathHelper::ApiV3Path.url_for(:storage_upload, storage.id)}?project_id=9277"
            end
            let(:upload_method) { :post }

            it_behaves_like "storage adapter: query call signature", "upload_link"
            it_behaves_like "adapter upload_link_query: successful upload link response"
          end
        end
      end
    end
  end
end
