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
require "rack/test"

RSpec.describe "API v3 THAPE meeting rooms", :webmock, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings] })
  end

  let(:api_url) { "http://meeting-booking.example/openapi/v1" }
  let(:rooms) do
    [
      { id: "线上会议", name: "线上会议", officeArea: "线上会议", officeAreaId: "online", showOrder: 1 },
      { id: "room-1", name: "Room 1", officeArea: "Shanghai", officeAreaId: "office-1", showOrder: 2 }
    ]
  end
  let(:parameters) do
    {
      title: "Online API meeting",
      startTime: "2030-06-02T14:00:00+08:00",
      duration: "PT1H",
      notify: false,
      _links: { project: { href: api_v3_paths.project(project.id) } }
    }
  end
  let(:booking_request) do
    stub_request(:post, "#{api_url}/book-meetings")
      .to_return_json(body: { code: 0, data: { id: "booking-1" } })
  end

  before do
    login_as user
    allow(ThMeetingBooking::Config).to receive_messages(host: "http://meeting-booking.example", path_prefix: "/openapi/v1")

    stub_request(:get, "#{api_url}/meeting-rooms")
      .with(query: { "roomType" => "ROOM" })
      .to_return_json(body: { code: 0, data: rooms, totalCount: rooms.size })
    stub_request(:get, "#{api_url}/meetings")
      .with(query: { "start" => "2030-06-02", "end" => "2030-06-02", "page" => "1", "pageSize" => "100" })
      .to_return_json(body: { code: 0, data: [], hasNextPage: false, totalPage: 1 })
    booking_request
  end

  it "defaults new meetings to the online room and persists it" do
    post api_v3_paths.meetings, parameters.to_json

    expect(last_response).to have_http_status(:created)
    meeting = Meeting.find(JSON.parse(last_response.body).fetch("id"))
    expect(meeting.th_meeting_upstream_room_id).to eq("线上会议")
    expect(meeting.start_time).to eq(Time.iso8601("2030-06-02T06:00:00Z"))
    expect(meeting.duration).to eq(1)
    expect(booking_request.with(body: hash_including("upstreamRoomId" => "线上会议"))).to have_been_requested.once

    get api_v3_paths.meeting(meeting.id)

    expect(last_response).to have_http_status(:ok)
    expect(last_response.body).to be_json_eql("线上会议".to_json).at_path("thMeetingUpstreamRoom")
    expect(last_response.body).to be_json_eql("线上会议 - 线上会议".to_json).at_path("location")
  end

  ["线上会议", "room-1"].each do |room_id|
    it "accepts the explicit room #{room_id} on creation" do
      post api_v3_paths.meetings, parameters.merge(thMeetingUpstreamRoom: room_id).to_json

      expect(last_response).to have_http_status(:created)
      expect(last_response.body).to be_json_eql(room_id.to_json).at_path("thMeetingUpstreamRoom")
      expect(booking_request.with(body: hash_including("upstreamRoomId" => room_id))).to have_been_requested.once
    end
  end

  it "exposes the default and writable field in the create form without booking" do
    post api_v3_paths.create_meeting_form, parameters.to_json

    expect(last_response).to have_http_status(:ok)
    expect(last_response.body).to have_json_size(0).at_path("_embedded/validationErrors")
    expect(last_response.body).to be_json_eql("线上会议".to_json).at_path("_embedded/payload/thMeetingUpstreamRoom")
    expect(last_response.body).to be_json_eql(true.to_json).at_path("_embedded/schema/thMeetingUpstreamRoom/writable")
    expect(last_response.body).to be_json_eql(true.to_json).at_path("_embedded/schema/thMeetingUpstreamRoom/hasDefault")
    expect(Meeting.count).to eq(0)
    expect(booking_request).not_to have_been_requested
  end

  it "retains an explicit room in the create form" do
    post api_v3_paths.create_meeting_form, parameters.merge(thMeetingUpstreamRoom: "room-1").to_json

    expect(last_response).to have_http_status(:ok)
    expect(last_response.body).to have_json_size(0).at_path("_embedded/validationErrors")
    expect(last_response.body).to be_json_eql("room-1".to_json).at_path("_embedded/payload/thMeetingUpstreamRoom")
    expect(booking_request).not_to have_been_requested
  end

  it "rejects an invalid room without creating a meeting or booking" do
    post api_v3_paths.meetings, parameters.merge(thMeetingUpstreamRoom: "missing-room").to_json

    expect(last_response).to have_http_status(:unprocessable_entity)
    expect(Meeting.count).to eq(0)
    expect(booking_request).not_to have_been_requested
  end

  context "with an existing physical meeting" do
    let(:meeting) do
      post api_v3_paths.meetings, parameters.merge(thMeetingUpstreamRoom: "room-1").to_json
      Meeting.find(JSON.parse(last_response.body).fetch("id"))
    end

    it "preserves the room when an update omits it" do
      patch api_v3_paths.meeting(meeting.id), { lockVersion: meeting.lock_version, title: "Updated title" }.to_json

      expect(last_response).to have_http_status(:ok)
      expect(meeting.reload.th_meeting_upstream_room_id).to eq("room-1")
      expect(booking_request).to have_been_requested.once
    end

    it "validates an online room in the update form without changing the booking" do
      post api_v3_paths.meeting_form(meeting.id),
           { lockVersion: meeting.lock_version, thMeetingUpstreamRoom: "线上会议" }.to_json

      expect(last_response).to have_http_status(:ok)
      expect(last_response.body).to have_json_size(0).at_path("_embedded/validationErrors")
      expect(last_response.body).to be_json_eql("线上会议".to_json).at_path("_embedded/payload/thMeetingUpstreamRoom")
      expect(meeting.reload.th_meeting_upstream_room_id).to eq("room-1")
      expect(booking_request).to have_been_requested.once
    end

    it "updates a physical meeting to online and returns the new room on subsequent reads" do
      get api_v3_paths.meeting(meeting.id)
      expect(last_response.body).to be_json_eql("room-1".to_json).at_path("thMeetingUpstreamRoom")

      patch api_v3_paths.meeting(meeting.id),
            { lockVersion: meeting.lock_version, thMeetingUpstreamRoom: "线上会议" }.to_json

      expect(last_response).to have_http_status(:ok)
      expect(meeting.reload.th_meeting_upstream_room_id).to eq("线上会议")
      expect(booking_request.with(body: hash_including("upstreamRoomId" => "线上会议"))).to have_been_requested.once

      get api_v3_paths.meeting(meeting.id)

      expect(last_response.body).to be_json_eql("线上会议".to_json).at_path("thMeetingUpstreamRoom")
      expect(last_response.body).to be_json_eql("线上会议 - 线上会议".to_json).at_path("location")
    end
  end
end
