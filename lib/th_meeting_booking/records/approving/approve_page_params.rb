module ThMeetingBooking::Records::Approving
  # 审批列表参数
  class ApprovePageParams < ThMeetingBooking::Records::Base
    Fields = [
      :type,
    ]

    attr_accessor(*Fields)
  end
end
