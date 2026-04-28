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

RSpec.describe "MCP configurations",
               :skip_csrf,
               type: :rails_request do
  shared_let(:admin) { create(:admin) }

  before do
    login_as admin
  end

  describe "POST /admin/mcp_configurations" do
    before do
      McpConfiguration.where(identifier: McpConfiguration::SERVER_CONFIGURATION_IDENTIFIER).delete_all
    end

    it "creates the missing server configuration from the server form" do
      expect do
        post "/admin/mcp_configurations",
             params: {
               mcp_configuration: {
                 enabled: "1"
               }
             }
      end.to change(McpConfiguration, :count).by(1)

      expect(response).to redirect_to(mcp_configurations_path)

      server_config = McpConfiguration.find_by!(identifier: McpConfiguration::SERVER_CONFIGURATION_IDENTIFIER)
      expect(server_config).to be_enabled
      expect(server_config.title).to eq(Setting.app_title)
      expect(server_config.description).to eq(McpConfiguration::SERVER_CONFIGURATION_DESCRIPTION)
    end
  end
end
