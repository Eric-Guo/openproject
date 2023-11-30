module ThMeetingBooking::Apis
  class Approving < Base
    # 审批列表查询
    # @param type [String] 审批状态，取值为：approve 待审批/passed 已通过/rejected 已拒绝/timeout 已过期/all 所有
    # @return [ThMeetingBooking::Records::Approving::ApproveList]
    def self.all_approves(type = 'approve')
      result = ThMeetingBooking::Request.new.get('all-approves', params: { type: })
      ThMeetingBooking::Records::Approving::ApproveList.new(result)
    end
  end
end
