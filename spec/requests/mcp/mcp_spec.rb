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
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "MCP endpoint" do
  describe "GET /mcp/" do
    it "responds with method not allowed" do
      get "/mcp/"

      expect(last_response).to have_http_status(:method_not_allowed)
      expect(last_response.media_type).to eq("application/json")
      expect(last_response.body).to be_json_eql(
        {
          jsonrpc: "2.0",
          error: {
            code: API::Mcp::ErrorRepresenter::INVALID_REQUEST,
            message: "405 Not Allowed",
            data: nil
          }
        }.to_json
      )
    end
  end
end
