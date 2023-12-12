class ThMeetingsController < ApplicationController
  def available_rooms
    start_date_time = params[:start_date_time]
    end_date_time = params[:end_date_time]
    th_meeting_id = params[:th_meeting_id]
    rooms = ThMeeting.available_rooms(start_date_time:, end_date_time:, th_meeting_id: nil)

    json = rooms.map do |room|
      {
        id: room.id,
        name: [room.office_area, room.name].join(' - '),
      }
    end

    render json:
  end
end
