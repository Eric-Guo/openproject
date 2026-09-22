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

require "spec_helper"

RSpec.describe "Meeting room selection", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings] }) }
  shared_let(:meeting) do
    build(:meeting, project:, author: user, state: :draft, start_time: 1.day.ago).tap do |meeting|
      meeting.save!(validate: false)
    end
  end

  let(:room) do
    instance_double(ThMeetingBooking::Records::Resource::MeetingRoom,
                    id: "room-1", office_area_id: "office-1", office_area: "Shanghai", name: "Room 1")
  end

  before do
    login_as user
    allow(ThMeeting).to receive(:available_rooms).and_return([room])
    allow(ThMeetingBooking::Apis::Resource).to receive(:meeting_rooms).and_return(Struct.new(:data).new([room]))
    allow(ThMeetingBooking::Apis::Booking).to receive(:sync_meetings)
  end

  it "renders the room selector and availability button" do
    get details_dialog_project_meeting_path(project, meeting), as: :turbo_stream

    expect(response).to have_http_status(:ok)
    dialog = Nokogiri::HTML.fragment(response.body)
    selector = dialog.at_css('select[name="meeting[th_meeting_upstream_room_id]"]')
    expect(selector.css("option").map(&:text)).to include("Shanghai - Room 1")
    expect(dialog.at_css('button[data-action="click->th-meeting-form#getAvailableRooms"]')).to be_present
  end

  it "saves a room and opens a past meeting without creating an external booking" do
    put update_details_project_meeting_path(project, meeting),
        params: { meeting: { th_meeting_upstream_room_id: room.id } },
        as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(meeting.reload.th_meeting_upstream_room_id).to eq(room.id)
    expect(meeting.location).to eq("Shanghai - Room 1")
    expect(meeting).to be_draft

    get details_dialog_project_meeting_path(project, meeting), as: :turbo_stream

    dialog = Nokogiri::HTML.fragment(response.body)
    expect(dialog.at_css('select[name="meeting[th_meeting_upstream_room_id]"] option[selected]')["value"]).to eq(room.id)

    post exit_draft_mode_project_meeting_path(project, meeting),
         params: { meeting: { notify: "0" } },
         as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(meeting.reload).to be_open
    expect(ThMeetingBooking::Apis::Booking).not_to have_received(:sync_meetings)
  end

  { "1" => true, "0" => false }.each do |submitted_value, enabled|
    it "opens a meeting with email updates #{enabled ? 'enabled' : 'disabled'}" do
      meeting.update!(th_meeting_upstream_room_id: room.id, notify: !enabled)

      post exit_draft_mode_project_meeting_path(project, meeting),
           params: { meeting: { notify: submitted_value } },
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(meeting.reload).to be_open
      expect(meeting.notify?).to eq(enabled)
    end
  end

  it "still creates an external booking for a future meeting" do
    meeting.update_column(:start_time, 1.day.from_now)
    allow(ThMeetingBooking::Apis::Booking).to receive(:sync_meetings).and_return(Struct.new(:id).new("booking-1"))

    put update_details_project_meeting_path(project, meeting),
        params: { meeting: { th_meeting_upstream_room_id: room.id } },
        as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(meeting.reload.th_meeting_upstream_room_id).to eq(room.id)
    expect(meeting.th_meeting_id).to eq("booking-1")
    expect(ThMeetingBooking::Apis::Booking).to have_received(:sync_meetings).once
  end
end
