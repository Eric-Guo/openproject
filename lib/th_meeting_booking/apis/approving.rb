module ThMeetingBooking::Apis
  class Approving < Base
    # 审批列表查询
    # @param type [String] 审批状态，取值为：approve 待审批/passed 已通过/rejected 已拒绝/timeout 已过期/all 所有
    # @return [ThMeetingBooking::Records::Approving::ApproveList]
    def self.all_approves(type = 'approve')
      result = ThMeetingBooking::Request.new.get('all-approves', params: { type: })
      ThMeetingBooking::Records::Approving::ApproveList.new(result)
    end

    # 审批会议
    # @param approve_meeting_id [String] 会议审批ID
    # @param approval: [Boolean] 是否同意；true 同意 / false 拒绝
    # @param approve_user: [String] 审批人登录名或邮箱或手机号，必须是当前会议指定的审批人才能审批通过
    # @param remark: [String] 审批说明
    # @return [String]
    def self.approve_meeting(approve_meeting_id, approval:, approve_user:, remark:)
      data = {
        approval:,
        approveUser: approve_user,
        remark:,
      }
      result = ThMeetingBooking::Request.new.post("approves/#{approve_meeting_id}", data:)
    end
  end
end
