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

module FullCalendar
  class TimeEntryEvent < Event
    attr_accessor :time_entry

    class << self
      def from_time_entry(time_entry)
        event = new(
          id: time_entry.id,
          starts_at: time_entry.start_timestamp || time_entry.spent_on,
          ends_at: time_entry.end_timestamp || time_entry.spent_on,
          all_day: time_entry.start_time.blank?,
          approved_by_id: time_entry.approved_by_id,
          title: "#{time_entry.project.name}: ##{time_entry.work_package.id} #{time_entry.work_package.subject}"
        )
        event.time_entry = time_entry

        event
      end
    end

    def additional_attributes
      {
        hours: time_entry.hours,
        typeId: time_entry.work_package.type_id,
        workPackageId: time_entry.work_package.id,
        workPackageSubject: time_entry.work_package.subject,
        projectId: time_entry.project.id,
        projectName: time_entry.project.name
      }
    end
  end
end
