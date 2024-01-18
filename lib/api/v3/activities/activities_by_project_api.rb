#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'api/v3/activities/activity_representer'

module API
  module V3
    module Activities
      class ActivitiesByProjectAPI < ::API::OpenProjectAPI
        resource :activities do
          get do
            self_link = api_v3_paths.project_activities @project.id

            from_date = API::V3::Utilities::DateTimeFormatter.parse_date(params[:from_date].presence, :from_date, allow_nil: true)
            to_date = API::V3::Utilities::DateTimeFormatter.parse_date(params[:to_date].presence, :to_date, allow_nil: true)

            journals = Journal.where(journable_type: 'WorkPackage')
                              .where(journable_id: @project.work_packages.ids)
                              .includes(:data,
                                        :customizable_journals,
                                        :attachable_journals,
                                        :bcf_comment)

            if from_date.present?
              journals = journals.where('journals.created_at >= ?', from_date)
            end

            if to_date.present?
              journals = journals.where('journals.created_at < ?', to_date + 1.day)
            end

            Activities::ActivityCollectionRepresenter.new(journals,
                                                          self_link:,
                                                          current_user:)
          end
        end
      end
    end
  end
end
