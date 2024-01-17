class ThMeeting < ApplicationRecord
  belongs_to :meeting

  after_save_commit do
    ThMeetings::SendToThMeetingBookingJob.perform_later(meeting_id)
  end

  # 获取有效的会议室列表
  # @param start_date_time: [String] 开始时间，格式YYYY-MM-DD HH:mm:ss
  # @param end_date_time: [String] 结束时间，格式YYYY-MM-DD HH:mm:ss
  # @param th_meeting_id: [String] 天华会议ID，判断时跳过该会议
  # @return [Array[ThMeetingBooking::Records::Resource::MeetingRoom]]
  def self.available_rooms(start_date_time:, end_date_time:, th_meeting_id: nil)
    busy_meeting_rooms = ThMeetingBooking::Apis::Resource.meeting_rooms(
      room_type: 'ROOM',
      begin_time: start_date_time,
      end_time: end_date_time,
      show_busy: true
    )

    ThMeetingBooking::Apis::Resource.meeting_rooms.data&.select do |room|
      busy_room = busy_meeting_rooms.data.detect { |item| item.id == room.id && (!item.online?) && item.is_busy }

      busy_room.nil? || (busy_room.busy_booking_ids.length == 1 && busy_room.busy_booking_ids[0] == th_meeting_id)
    end
  end
end
