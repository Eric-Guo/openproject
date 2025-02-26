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

# rubocop:disable Lint/PercentStringArray
Rails.application.config.after_initialize do
  SecureHeaders::Configuration.default do |config|
    config.cookies = {
      secure: true,
      httponly: true
    }

    # Let Rails ActionDispatch::SSL middleware handle the Strict-Transport-Security header
    config.hsts = SecureHeaders::OPT_OUT

    config.x_frame_options = "SAMEORIGIN"
    config.x_content_type_options = "nosniff"
    config.x_xss_protection = "1; mode=block"
    config.x_permitted_cross_domain_policies = "none"
    config.referrer_policy = "origin-when-cross-origin"

    # Valid for assets
    assets_src = ["'self'"]
    asset_host = OpenProject::Configuration.rails_asset_host
    assets_src << asset_host if asset_host.present?
    assets_src += %w('unsafe-eval' 'unsafe-inline')

    # Valid for iframes
    frame_src = %w['self' https://dify.thape.com.cn https://ith-workspace.thape.com.cn]
    frame_src << OpenProject::Configuration[:security_badge_url]

    # Default src
    default_src = %w('self')

    # Attachment uploaders
    default_src += OpenProject::Configuration.remote_storage_hosts

    # Chargebee self-service
    frame_src += [
      "https://js.chargebee.com/",
      "#{OpenProject::Configuration.enterprise_chargebee_site}.chargebee.com"
    ]

    default_src << "#{OpenProject::Configuration.enterprise_chargebee_site}.chargebee.com"

    # Allow requests to CLI in dev mode
    connect_src = default_src + [OpenProject::Configuration.enterprise_trial_creation_host]

    # Rules for media (e.g. video sources)
    media_src = default_src
    media_src << asset_host if asset_host.present?

    if OpenProject::Configuration.appsignal_frontend_key
      connect_src += ["https://appsignal-endpoint.net"]
    end

    if ENV["CSP_CONNECT_SRC"].present?
      connect_src << ENV["CSP_CONNECT_SRC"]
    end

    # Add proxy configuration for Angular CLI to csp
    if FrontendAssetHelper.assets_proxied?
      proxied = ["ws://#{Setting.host_name}", "http://#{Setting.host_name}",
                 FrontendAssetHelper.cli_proxy.sub("http", "ws"), FrontendAssetHelper.cli_proxy]
      connect_src += proxied
      assets_src += proxied
      media_src += proxied
    end

    # Allow to extend the script-src in specific situations
    script_src = assets_src + %w(js.chargebee.com)

    # Allow unsafe-eval for rack-mini-profiler
    if Rails.env.development? && ENV.fetch("OPENPROJECT_RACK_PROFILER_ENABLED", false)
      script_src += %w('unsafe-eval')
    end

    # Allow ANDI bookmarklet to run in development mode
    # https://www.ssa.gov/accessibility/andi/help/install.html
    if Rails.env.development?
      script_src += ["https://www.ssa.gov"]
      assets_src += ["https://www.ssa.gov"]
    end

    config.csp = {
      preserve_schemes: true,
      # Don't append unsafe-inline in CSP as a fallback
      disable_nonce_backwards_compatibility: true,

      # Fallback when no value is defined
      default_src:,
      # Allowed uri in <base> tag
      base_uri: %w('self'),

      # Allow fonts from self, asset host, or DATA uri
      font_src: assets_src + %w(data: 'self'),
      # Form targets can only be self
      form_action: default_src,
      # Allow iframe from vimeo (welcome video)
      frame_src: frame_src + %w('self'),
      frame_ancestors: %w('self'),
      # Allow images from anywhere including data urls and blobs (used in resizing)
      img_src: %w(* data: blob:),
      # Allow scripts from self
      script_src:,
      script_src_attr: %w('none'),
      # Allow unsafe-inline styles
      style_src: assets_src + %w('unsafe-inline'),
      # Allow object-src from Release API
      object_src: [OpenProject::Configuration[:security_badge_url]],

      # Connect sources for CLI in dev mode
      connect_src:,

      # Allow videos from self and from the asset proxy in dev mode.
      media_src:
    }
  end
end
# rubocop:enable Lint/PercentStringArray
