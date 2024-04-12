#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Meeting::ThMeetingUpstreamRoomId < ApplicationForm
  form do |meeting_form|
    meeting_form.select_list(
      name: :th_meeting_upstream_room_id,
      label: Meeting.human_attribute_name(:th_meeting_upstream_room_id),
      visually_hide_label: false,
      leading_visual: { icon: :link }
    ) do |select_list|
      select_list.option(label: '请选择会议室', value: '')
      ThMeeting.available_rooms(
        start_date_time: @meeting.start_date_time,
        end_date_time: @meeting.end_date_time,
        th_meeting_id: @meeting.th_meeting_id
      ).each do |item|
        select_list.option(label: [item.office_area, item.name].join(' - '), value: item.id)
      end
    end
  end

  def initialize(meeting:)
    @meeting = meeting
  end
end
