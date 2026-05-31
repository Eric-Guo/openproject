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
          RSpec.describe OpenFileLinkQuery do
            let(:storage) { build(:edoc_dds_storage) }
            let(:auth_strategy) { Registry["edoc_dds.authentication.userless"].call }

            it_behaves_like "storage adapter: query call signature", "open_file_link"

            context "with a file link" do
              let(:input_data) { Input::OpenFileLink.build(file_id: "file:306").value! }
              let(:open_file_link) { "https://annotator.thape.com.cn/?file_id=306" }

              it_behaves_like "adapter open_file_link_query: successful link response"
            end

            context "with a folder link" do
              let(:input_data) { Input::OpenFileLink.build(file_id: "folder:200").value! }
              let(:open_file_link) { "https://dds.example.com/index.html#doc/enterprise/200" }

              it_behaves_like "adapter open_file_link_query: successful link response"
            end
          end
        end
      end
    end
  end
end
