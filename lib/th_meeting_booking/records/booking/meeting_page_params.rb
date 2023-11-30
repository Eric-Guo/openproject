module ThMeetingBooking::Records::Booking
  # 会议列表参数
  class MeetingPageParams < ThMeetingBooking::Records::Base
    Fields = [
      :start,
      :end,
      :subject,
    ]

    attr_accessor(*Fields)
  end
end
