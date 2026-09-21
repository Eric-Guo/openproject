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
  class ExternalSharesController < ApplicationController
    include OpTurbo::ComponentStream

    authorization_checked! :new, :create
    before_action :find_resources
    before_action :authorize_sharing

    def new
      show_dialog
    end

    def create
      result = FileLinks::CreateExternalShareService.new(user: current_user, work_package: @work_package,
                                                         project_storage: @project_storage)
                                                  .call(file_link_ids: selected_ids, expiration: expiration)
      if result.success?
        show_dialog(share: result.result)
      else
        show_dialog(error: result.message, status: :unprocessable_entity)
      end
    end

    private

    def find_resources
      @work_package = WorkPackage.visible(current_user).find(params.expect(:work_package_id))
      @project_storage = @work_package.project.project_storages.find(params.expect(:project_storage_id))
      render_404 unless FileLinks::CreateExternalShareService.available?(@project_storage.storage)
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def authorize_sharing
      project = @work_package.project
      unless current_user.allowed_in_project?(:view_file_links, project) &&
             current_user.allowed_in_project?(:manage_file_links, project)
        deny_access
      end
    end

    def selected_ids
      params.permit(file_link_ids: []).fetch(:file_link_ids, []).map(&:to_s)
    end

    def expiration
      params[:expiration].presence || "week"
    end

    def show_dialog(share: nil, error: nil, status: :ok)
      file_links = ::Storages::FileLink.where(container: @work_package, storage: @project_storage.storage)
                                    .order(:origin_name, :id)
                                    .select { FileLinks::CreateExternalShareService.shareable?(it) }
      respond_with_dialog(
        ExternalShares::DialogComponent.new(work_package: @work_package, project_storage: @project_storage,
                                            file_links:, selected_ids:, expiration:, share:, error:),
        status:
      )
    end
  end
end
