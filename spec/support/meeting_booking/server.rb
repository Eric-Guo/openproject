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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "webrick"

module MeetingBookingSpecServer
  ROOM = { id: "online-room", name: "Online room", officeArea: "线上会议", officeAreaId: "online", disabled: false }.freeze

  def self.build
    server = WEBrick::HTTPServer.new(BindAddress: "127.0.0.1", Port: 0, AccessLog: [], Logger: WEBrick::Log.new(File::NULL))
    server.mount_proc "/meeting-rooms" do |_request, response|
      response.body = { code: 0, data: [ROOM], totalCount: 1 }.to_json
    end
    server.mount_proc "/meetings" do |request, response|
      if request.request_method == "GET" && request.path == "/meetings"
        response.body = { code: 0, data: [], hasNextPage: false }.to_json
      elsif request.request_method == "POST" && request.path.match?(%r{\A/meetings/[^/]+/(?:cancel|finish)\z})
        response.body = { code: 0, data: { id: request.path.split("/")[2] } }.to_json
      else
        response.status = 404
      end
    end
    server.mount_proc "/book-meetings" do |request, response|
      response.body = { code: 0, data: { id: JSON.parse(request.body).fetch("upstreamId") } }.to_json
    end
    server.mount_proc "/sync-meetings" do |_request, response|
      response.body = { code: 0, data: {} }.to_json
    end
    server
  end
end

RSpec.configure do |config|
  server = nil
  thread = nil
  previous = {}

  config.before(:suite) do
    server = MeetingBookingSpecServer.build
    {
      "HOST" => "http://127.0.0.1:#{server.config[:Port]}",
      "PATH_PREFIX" => "/", "APP_ID" => "rspec", "APP_SECRET" => "rspec", "PREFIX_KEY" => "rspec"
    }.each do |key, value|
      name = "TH_MEETING_BOOKING_#{key}"
      previous[name] = ENV.fetch(name, nil)
      ENV[name] = value
    end
    thread = Thread.new { server.start }
  end

  config.after(:suite) do
    server&.shutdown
    thread&.join
    previous.each { |name, value| ENV[name] = value }
  end
end
