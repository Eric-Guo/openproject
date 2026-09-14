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

RSpec.describe "OpenID Connect content security policy", type: :rails_request do
  include CspHelper

  let(:authorization_endpoint) { "https://sso.thape.com.cn/oauth/authorize" }
  let!(:provider) { create(:oidc_provider, slug: "openid_connect", authorization_endpoint:) }
  let(:csp) { parse_csp(response.headers.fetch("Content-Security-Policy")) }

  it "allows the SSO button's POST redirect to the configured authorization origin" do
    get signin_path

    form = response.parsed_body.at_css('form[action="/auth/openid_connect"]')
    expect(form["method"]).to eq("post")
    allowed_origins = csp.fetch("form-action")
    expect(allowed_origins).to include("'self'", "https://sso.thape.com.cn")

    post form["action"], params: { authenticity_token: form.at_css('input[name="authenticity_token"]')["value"] }

    expect(response).to have_http_status(:found)
    expect(response.location).to start_with("#{authorization_endpoint}?")
    expect(allowed_origins).to include(Addressable::URI.parse(response.location).origin)
  end

  it "only extends form-action for the identity provider" do
    get signin_path

    %w[default-src connect-src script-src].each do |directive|
      expect(csp.fetch(directive)).not_to include("https://sso.thape.com.cn")
    end
  end

  context "with direct login", with_settings: { omniauth_direct_login_provider: "openid_connect" } do
    it "allows the automatically submitted login form to redirect to the provider" do
      get signin_path

      expect(response.parsed_body.at_css("#omniauth-direct-login-form")).to be_present
      expect(csp.fetch("form-action")).to include("https://sso.thape.com.cn")
    end
  end

  context "on a public page", with_settings: { login_required: false } do
    it "allows the login menu's SSO form to redirect to the provider" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(csp.fetch("form-action")).to include("https://sso.thape.com.cn")
    end
  end

  it "excludes unavailable providers" do
    provider.update!(available: false)

    get signin_path

    expect(csp.fetch("form-action")).not_to include("https://sso.thape.com.cn")
  end

  it "uses updated provider settings on the next request" do
    get signin_path
    expect(csp.fetch("form-action")).to include("https://sso.thape.com.cn")

    provider.update!(authorization_endpoint: "https://new-sso.example.com/oauth/authorize")
    get signin_path

    updated_csp = parse_csp(response.headers.fetch("Content-Security-Policy"))
    expect(updated_csp.fetch("form-action")).to include("https://new-sso.example.com")
    expect(updated_csp.fetch("form-action")).not_to include("https://sso.thape.com.cn")
  end

  context "with a relative authorization endpoint and a custom port" do
    let(:authorization_endpoint) { "/oauth/authorize" }

    before do
      provider.update!(host: "sso.example.com", scheme: "https", port: "8443")
    end

    it "allows the resolved authorization origin including the port" do
      get signin_path

      expect(csp.fetch("form-action")).to include("https://sso.example.com:8443")
    end
  end

  { "google" => "https://accounts.google.com", "microsoft_entra" => "https://login.microsoftonline.com" }.each do |type, origin|
    context "with the built-in #{type} provider defaults" do
      before do
        provider.update!(oidc_provider: type, host: nil, authorization_endpoint: nil)
      end

      it "allows the built-in authorization origin" do
        get signin_path

        expect(csp.fetch("form-action")).to include(origin)
      end
    end
  end
end
