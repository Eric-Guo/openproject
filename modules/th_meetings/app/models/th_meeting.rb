class ThMeeting < ApplicationRecord
  belongs_to :meeting

  after_commit do
    ThMeetings::SendToThMeetingBookingJob.perform_later(meeting_id)
  end
end
