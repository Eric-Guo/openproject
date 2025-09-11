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
    no_authorization_required! :show, :welcome

    current_menu_item [:show] do
      :my_page
    end

    def show
      respond_to do |format|
        format.html do
          @query_due_date = Query.find 81614 # 我的逾期工作包
          @query_due_date.sort_criteria = [["due_date", "desc"]]
          @query_need_confirm = Query.find 81615 # 我的待复核工作包
          @query_need_confirm.sort_criteria = [["due_date", "desc"]]
          render locals: { menu_name: :global_menu }
        end
      end
    end

    def welcome
      respond_to do |format|
        format.turbo_stream
      end
    end
  end
end
