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
  class EdocDdsStorage < Storage
    PROVIDER_FIELDS_DEFAULTS = {
      automatically_managed: false,
      automatic_management_enabled: false
    }.freeze

    store_attribute :provider_fields, :root_folder_id, :string
    store_attribute :provider_fields, :token, :string

    def self.short_provider_name = :edoc_dds

    def self.non_confidential_provider_fields
      super + %i[root_folder_id]
    end

    def supports_oauth_redirect? = false

    def oauth_access_granted?(_) = true

    def audience = nil

    def authenticate_via_idp? = false

    def authenticate_via_storage? = false

    def available_project_folder_modes = %w[inactive manual]

    def oauth_configuration = nil

    def automatic_management_new_record? = false

    def provider_fields_defaults = PROVIDER_FIELDS_DEFAULTS

    def configuration_checks
      {
        host_name_configured: host.present? && name.present?,
        edoc_dds_root_folder_configured: root_folder_id.present?,
        edoc_dds_token_configured: token.present?,
        access_management_configured: true,
        name_configured: name.present?
      }
    end
  end
end
