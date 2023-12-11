class ThMeetings::CancelThMeetingBookingJob < ApplicationJob
  queue_with_priority :above_normal

  def perform(meeting_id)
    th_meeting = ThMeeting.find_by(meeting_id:)

    return unless th_meeting.present? && th_meeting.th_meeting_id.present?

    ThMeetingBooking::Apis::Booking.cancel_meeting(th_meeting.th_meeting_id, reason: '无')
  end
end
