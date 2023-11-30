module ThMeetingBooking::Records::Approving
  # 审核人信息，示例数据如下
  # ```JSON
  # {
  #   "id": "LkTkWPMjSLG56SdZ8WXVGM",
  #   "name": "段敏",
  #   "namePinyin": "Duan Min",
  #   "position": "机械技术工程师",
  #   "jobNumber": "20110191",
  #   "nickName": "Duan Min",
  #   "loginName": "20110191",
  #   "mobile": "18614095268",
  #   "status": "ACTIVE",
  #   "upstreamId": "57d0fadfe4b0a473949a5e5a",
  #   "labelName": "段敏",
  #   "joinAt": "",
  #   "checkAt": ""
  # }
  # ```
  class ApproveUser < ThMeetingBooking::Records::Base
    Fields = [
      :id,
      :name,
      :namePinyin,
      :position,
      :jobNumber,
      :nickName,
      :loginName,
      :mobile,
      :status,
      :upstreamId,
      :labelName,
      :joinAt,
      :checkAt,
    ]

    attr_accessor(*Fields)
  end
end
