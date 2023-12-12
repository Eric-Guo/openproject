class ThMeeting < ApplicationRecord
  belongs_to :meeting

  after_save_commit do
    ThMeetings::SendToThMeetingBookingJob.perform_later(meeting_id)
  end

  # 获取有效的会议室列表
  # @param start_date: [String] 开始时间，格式YYYY-MM-DD HH:mm:ss
  # @param end_date: [String] 结束时间，格式YYYY-MM-DD HH:mm:ss
  # @param th_meeting_id: [String] 天华会议ID，判断时跳过该会议
  # @return [Array[ThMeetingBooking::Records::Resource::MeetingRoom]]
  def self.available_rooms(start_date_time:, end_date_time:, th_meeting_id: nil)
    start_date = start_date_time.slice(0, 10)
    end_date = end_date_time.slice(0, 10)

    meetings = ThMeetingBooking::Apis::Booking.meetings(start_date:, end_date:)
    ThMeetingBooking::Apis::Resource.meeting_rooms.data&.select do |room|
      occupied = meetings.data.any? do |meeting|
        if room.id == meeting.room_id
          if meeting.id == th_meeting_id
            false
          else
            !(start_date_time >= meeting.end_time || end_date_time <= meeting.begin_time)
          end
        else
          false
        end
      end
      !occupied
    end
  end
end
