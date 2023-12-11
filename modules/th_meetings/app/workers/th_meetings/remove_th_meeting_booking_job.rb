class ThMeetings::RemoveThMeetingBookingJob < ApplicationJob
  queue_with_priority :above_normal

  def perform(meeting_id)
    th_meeting = ThMeeting.find_by(meeting_id:)

    return unless th_meeting.present? && th_meeting.th_meeting_id.present?

    result = ThMeetingBooking::Apis::Booking.remove_sync_meeting(
      upstream_id: th_meeting.upstream_id,
      upstream_room_id: th_meeting.upstream_room_id,
      booking_user_id: th_meeting.booking_user_id,
      booking_user_name: th_meeting.booking_user_name,
      booking_user_email: th_meeting.booking_user_email,
      booking_user_phone: th_meeting.booking_user_phone,
      subject: th_meeting.subject,
      content: th_meeting.content,
      begin_time: th_meeting.begin_time,
      end_time: th_meeting.end_time
    )
  end
end
