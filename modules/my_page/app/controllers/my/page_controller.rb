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
module My
  class PageController < ApplicationController
    before_action :require_login
    no_authorization_required! :show, :welcome, :hide_welcome

    current_menu_item [:show] do
      :my_page
    end

    def show
      respond_to do |format|
        format.html do
          @auto_load_welcome = auto_load_welcome?
          @query_due_date = Query.find 81614 # 我的逾期工作包
          @query_due_date.sort_criteria = [["due_date", "desc"]]
          @query_need_confirm = Query.find 81615 # 我的待复核工作包
          @query_need_confirm.sort_criteria = [["due_date", "desc"]]
          @one_news = News.where(project_id: 1157).latest(count: 4).sample
          update_milestone_project_resp = get_update_milestone_project
          unless update_milestone_project_resp.cancelled
            @update_milestone_projects = Project.where(id: update_milestone_project_resp.message.projectIds.to_a) # otherwise will be Google::Protobuf::RepeatedField
          end
          archive_projects_resp = get_archive_projects
          unless archive_projects_resp.cancelled
            @archive_projects = Project.where(id: archive_projects_resp.message.projectIds.to_a)
            @archive_projects_url = archive_projects_resp.message.url
          end
          budget_overrun_projects_resp = get_budget_overrun_projects
          unless budget_overrun_projects_resp.cancelled
            @show_budget_overrun_projects = budget_overrun_projects_resp.message.show
            @budget_overrun_projects = Project.where(id: budget_overrun_projects_resp.message.projectIds.to_a)
          end
          render locals: { menu_name: :global_menu }
        end
      end
    end

    def welcome
      current_user&.mark_welcome_text_viewed!

      respond_to do |format|
        format.turbo_stream
        format.html { render :welcome }
      end
    end

    def hide_welcome
      respond_to do |format|
        format.turbo_stream
      end
    end

    private

    def auto_load_welcome?
      return false unless Setting.welcome_text.present?

      welcome_updated_at = Setting.where(name: "welcome_text").pick(:updated_at)
      return false unless welcome_updated_at

      last_viewed_at = current_user.view_welcome_text_time

      last_viewed_at.nil? || welcome_updated_at > last_viewed_at
    end

    def get_update_milestone_project
      Proto::OpService::Service.current_client.call(
        :GetUpdateMilestoneProject,
        {
          UserID: current_user.id
        }
      )
    end

    def get_archive_projects
      Proto::OpService::Service.current_client.call(
        :GetArchiveProjects,
        {
          UserID: current_user.id
        }
      )
    end

    def get_budget_overrun_projects
      Proto::OpService::Service.current_client.call(
        :GetBudgetOverrunProjects,
        {
          UserID: current_user.id
        }
      )
    end
  end
end
