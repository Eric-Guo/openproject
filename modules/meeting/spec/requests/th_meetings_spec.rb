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

RSpec.describe "TH meeting room availability", :webmock, type: :rails_request do
  shared_let(:user) { create(:user) }

  let(:api_url) { "http://meeting-booking.example/openapi/v1" }
  let(:start_date_time) { "2030-06-02 10:00:00" }
  let(:end_date_time) { "2030-06-02 11:00:00" }
  let(:request_params) { { start_date_time:, end_date_time:, show_busy: "false" } }
  let(:rooms) do
    [
      { id: "room-1", name: "Room 1", officeArea: "Shanghai", showOrder: 1, currentStatus: "FREE", isBusy: false },
      { id: "room-2", name: "Room 2", officeArea: "Shanghai", showOrder: 2, currentStatus: "FREE", isBusy: false }
    ]
  end
  let(:bookings) do
    [{ id: "booking-1", roomId: "room-1", beginTime: start_date_time, endTime: end_date_time, status: "OPEN" }]
  end
  let(:bookings_response) { { code: 0, data: bookings, hasNextPage: false, totalPage: 1 } }

  before do
    login_as user
    allow(ThMeetingBooking::Config).to receive_messages(host: "http://meeting-booking.example", path_prefix: "/openapi/v1")

    stub_request(:get, "#{api_url}/meeting-rooms")
      .with(query: hash_including("roomType" => "ROOM"))
      .to_return_json(body: { code: 0, data: rooms, totalCount: rooms.size })

    stub_request(:get, "#{api_url}/meetings")
      .with(query: { "start" => start_date_time.split.first, "end" => end_date_time.split.first,
                     "page" => "1", "pageSize" => "100" })
      .to_return_json(body: bookings_response)
  end

  def available_room_ids
    get available_rooms_th_meetings_path, params: request_params, as: :json

    expect(response).to have_http_status(:ok)
    response.parsed_body.pluck("id")
  end

  it "filters occupied rooms even when the room API reports every room as free" do
    expect(available_room_ids).to eq(["room-2"])
    expect(response.parsed_body).to eq([{ "id" => "room-2", "name" => "Shanghai - Room 2" }])
  end

  [nil, "true"].each do |show_busy|
    context "with show_busy=#{show_busy.inspect}" do
      let(:request_params) { { start_date_time:, end_date_time:, show_busy: }.compact }

      it "still excludes occupied rooms" do
        expect(available_room_ids).to eq(["room-2"])
      end
    end
  end

  {
    "ending at the requested start" => ["09:00:00", "10:00:00", true],
    "starting at the requested end" => ["11:00:00", "12:00:00", true],
    "overlapping the requested start" => ["09:30:00", "10:30:00", false],
    "overlapping the requested end" => ["10:30:00", "11:30:00", false],
    "inside the requested interval" => ["10:15:00", "10:45:00", false],
    "containing the requested interval" => ["09:00:00", "12:00:00", false]
  }.each do |description, (begin_time, end_time, available)|
    context "with a booking #{description}" do
      let(:bookings) do
        [{ id: "booking-1", roomId: "room-1", beginTime: "2030-06-02 #{begin_time}", endTime: "2030-06-02 #{end_time}" }]
      end

      it "checks the actual time overlap" do
        expect(available_room_ids).to eq(available ? ["room-1", "room-2"] : ["room-2"])
      end
    end
  end

  context "when editing the room's existing booking" do
    let(:request_params) { super().merge(th_meeting_id: "booking-1") }

    it "keeps the room available" do
      expect(available_room_ids).to eq(["room-1", "room-2"])
    end

    context "with another conflicting booking in the same room" do
      let(:bookings) { [*super(), super().first.merge(id: "booking-2")] }

      it "excludes the room" do
        expect(available_room_ids).to eq(["room-2"])
      end
    end
  end

  context "when the conflict is on a later page" do
    let(:bookings_response) { { code: 0, data: [], hasNextPage: true, totalPage: 2 } }

    before do
      stub_request(:get, "#{api_url}/meetings")
        .with(query: { "start" => "2030-06-02", "end" => "2030-06-02", "page" => "2", "pageSize" => "100" })
        .to_return_json(body: { code: 0, data: bookings, hasNextPage: false, totalPage: 2 })
    end

    it "excludes the occupied room" do
      expect(available_room_ids).to eq(["room-2"])
    end
  end

  context "when there are no bookings" do
    let(:bookings) { [] }

    it "returns all rooms" do
      expect(available_room_ids).to eq(["room-1", "room-2"])
    end
  end

  context "with an online room" do
    let(:rooms) { super().map { |room| room[:id] == "room-1" ? room.merge(officeArea: "线上会议") : room } }

    it "keeps online rooms available despite overlapping bookings" do
      expect(available_room_ids).to eq(["room-1", "room-2"])
    end
  end

  context "with a disabled room" do
    let(:rooms) { super().map { |room| room.merge(disabled: true) } }
    let(:bookings) { [] }

    it "excludes disabled rooms" do
      expect(available_room_ids).to be_empty
    end
  end

  context "with a meeting that crosses midnight" do
    let(:start_date_time) { "2030-06-02 23:30:00" }
    let(:end_date_time) { "2030-06-03 00:30:00" }
    let(:bookings) do
      [{ id: "booking-1", roomId: "room-1", beginTime: "2030-06-02 00:00:00", endTime: "2030-06-03 00:00:00" }]
    end

    it "excludes rooms with overlapping all-day bookings" do
      expect(available_room_ids).to eq(["room-2"])
    end
  end

  context "when the booking server fails" do
    before do
      stub_request(:get, "#{api_url}/meetings").with(query: hash_including({})).to_return(status: 503)
    end

    it "does not return occupied rooms as available" do
      expect { available_room_ids }.to raise_error(StandardError, /503/)
    end
  end
end
