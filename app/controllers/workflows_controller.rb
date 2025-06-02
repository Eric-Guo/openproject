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

class WorkflowsController < ApplicationController
  include OpTurbo::ComponentStream

  layout "admin"

  before_action :require_admin

  before_action :find_roles, except: :update
  before_action :find_types, except: %i[edit update]

  before_action :find_role, only: %i[update confirmation_dialog]
  before_action :find_type, only: %i[edit update confirmation_dialog]

  before_action :find_optional_role, only: %i[edit status_dialog confirm_statuses]
  before_action :find_optional_type, only: %i[edit status_dialog confirm_statuses]

  def index; end

  def summarized
    @workflow_counts = Workflow.count_by_type_and_role
    @roles = @workflow_counts.first&.last&.map(&:first)
  end

  def edit
    @current_tab = current_tab
    statuses_for_form

    if @type && @role && @statuses.any?
      workflows_for_form
    end
  end

  def update # rubocop:disable Metrics/AbcSize
    tab = params[:tab] || "always"

    call = Workflows::BulkUpdateService
           .new(role: @role, type: @type, tab:)
           .call(permitted_status_params)

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      next_role_id = params[:next_role_id].presence
      next_tab = params[:next_tab].presence
      redirect_to edit_workflow_path(@type, role_id: next_role_id || @role.id, tab: next_tab || tab)
    end
  end

  def copy
    @source_type = if params[:source_type_id].blank? || params[:source_type_id] == "any"
                     nil
                   else
                     ::Type.find(params[:source_type_id])
                   end
    @source_role = if params[:source_role_id].blank? || params[:source_role_id] == "any"
                     nil
                   else
                     eligible_roles.find(params[:source_role_id])
                   end

    @target_types = params[:target_type_ids].blank? ? nil : ::Type.where(id: params[:target_type_ids])
    @target_roles = params[:target_role_ids].blank? ? nil : eligible_roles.where(id: params[:target_role_ids])

    if request.post?
      if params[:source_type_id].blank? || params[:source_role_id].blank? || (@source_type.nil? && @source_role.nil?)
        flash.now[:error] = I18n.t(:error_workflow_copy_source)
      elsif @target_types.nil? || @target_roles.nil?
        flash.now[:error] = I18n.t(:error_workflow_copy_target)
      else
        Workflow.copy(@source_type, @source_role, @target_types, @target_roles)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to action: "copy", source_type_id: @source_type, source_role_id: @source_role
      end
    end
  end

  def confirmation_dialog # rubocop:disable Metrics/AbcSize
    destination_role_id = params[:next_role_id].presence || @role.id
    destination_tab = params[:next_tab].presence || current_tab
    destination_url = edit_workflow_path(@type, role_id: destination_role_id, tab: destination_tab)

    if params[:dirty] == "true"
      # Necessary because the ActionMenu updates even when the confirmation dialog
      # is closed via "X". This update ensures the correct option is shown as selected
      # with a preceding checkbox at all times
      update_via_turbo_stream(
        component: Workflows::EditSubHeaderComponent.new(
          tab: current_tab,
          current_role: @role,
          type: @type,
          available_roles: @roles,
          status_ids: [],
          dirty: true
        )
      )
      respond_with_dialog Workflows::ConfirmationDialogComponent.new(
        redirect_url: destination_url,
        next_role_id: params[:next_role_id].presence,
        next_tab: params[:next_tab].presence
      )
    else
      redirect_to destination_url, status: :see_other
    end
  end

  def status_dialog
    all_statuses = Status.order(:position)
    current_statuses = if params[:status_ids].present?
                         Status.where(id: params[:status_ids].map(&:to_i)).order(:position)
                       elsif @type && @role
                         statuses_for_role_and_type
                       else
                         Status.none
                       end

    respond_with_dialog Workflows::StatusDialogComponent.new(
      all_statuses:,
      current_statuses:,
      role: @role,
      type: @type,
      tab: params[:tab] || "always"
    )
  end

  def confirm_statuses # rubocop:disable Metrics/AbcSize
    current_status_ids = Array(params[:status_ids]).flatten.map(&:to_i)
    original_ids = Array(params[:original_status_ids]).flatten.map(&:to_i)
    removed_count = (original_ids - current_status_ids).size

    if removed_count > 0
      respond_with_dialog Workflows::StatusRemovalDangerDialogComponent.new(
        role: @role,
        type: @type,
        tab: params[:tab] || "always",
        status_ids: current_status_ids,
        removed_count: removed_count
      )
    else
      redirect_to edit_workflow_path(
        params[:type_id],
        role_id: params[:role_id],
        tab: params[:tab] || "always",
        status_ids: current_status_ids
      ), status: :see_other
    end
  end

  private

  def statuses_for_form
    @added_status_ids = []
    @has_status_changes = false
    @statuses = if @type && params[:status_ids].present?
                  statuses_from_params
                elsif @type && @role
                  statuses_for_role_and_type
                elsif @type
                  @type.statuses
                else
                  Status.all
                end
  end

  def statuses_from_params
    status_ids = params[:status_ids].map(&:to_i)
    saved_ids = statuses_for_role_and_type.pluck(:id)
    @added_status_ids = status_ids - saved_ids
    @has_status_changes = @added_status_ids.any? || (saved_ids - status_ids).any?
    Status.where(id: status_ids).order(:position)
  end

  def statuses_for_role_and_type
    @type.statuses(role: @role, tab: current_tab)
  end

  def current_tab
    params[:tab] || "always"
  end

  def workflows_for_form
    workflows = Workflow.where(role_id: @role.id, type_id: @type.id)
    @workflows = {}
    @workflows["always"] = workflows.select { |w| !w.author && !w.assignee }
    @workflows["author"] = workflows.select(&:author)
    @workflows["assignee"] = workflows.select(&:assignee)
  end

  def find_roles
    @roles = eligible_roles.order(:builtin, :position)
  end

  def find_types
    @types = ::Type.order(:position)
  end

  def find_role
    @role = eligible_roles.find(params[:role_id])
  end

  def find_type
    @type = ::Type.find(params[:type_id])
  end

  def find_optional_role
    @role = eligible_roles.find_by(id: params[:role_id]) || eligible_roles.order(:builtin, :position).first
  end

  def find_optional_type
    @type = ::Type.find_by(id: params[:type_id]) || ::Type.order(:position).first
  end

  def eligible_roles
    roles = Role.where(type: ProjectRole.name)

    roles.or(Role.where(builtin: Role::BUILTIN_WORK_PACKAGE_EDITOR))
  end

  def permitted_status_params
    return {} if params["status"].blank?

    params["status"]
      .to_unsafe_h
      .select { |key, value| /\A\d+\z/.match?(key) && value.keys.all? { /\A\d+\z/.match?(it) } }
  end
end
