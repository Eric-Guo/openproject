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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module ExternalShares
    class DialogComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      DIALOG_ID = "dds-external-share-dialog"
      FORM_ID = "dds-external-share-form"

      attr_reader :work_package, :project_storage, :file_links, :selected_ids, :expiration, :share, :error

      def initialize(work_package:, project_storage:, file_links:, selected_ids:, expiration:, share: nil, error: nil)
        super()
        @work_package = work_package
        @project_storage = project_storage
        @file_links = file_links
        @selected_ids = selected_ids
        @expiration = expiration
        @share = share
        @error = error
      end

      def title
        t("storages.external_shares.#{share ? 'result_title' : 'title'}")
      end

      def expiration_options
        FileLinks::CreateExternalShareService::EXPIRATIONS.keys.map do |key|
          [t("storages.external_shares.expirations.#{key}"), key]
        end
      end
    end
  end
end
