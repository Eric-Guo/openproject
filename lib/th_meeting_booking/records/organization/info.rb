module ThMeetingBooking::Records::Organization
  # 部门信息，示例数据如下
  # ```JSON
  # {
  #   "id": "5HqXn3Bpgits6WVbRjXpVY",
  #   "name": "双杰测试",
  #   "meetingRoomCount": 3,
  #   "customCorpUrl": "https://sojo.rt.v-vip.cn",
  #   "customCorpDomain": "sojo.rt.v-vip.cn",
  #   "abilities": []
  # }
  # ```
  class Info < ThMeetingBooking::Records::Base
    Fields = [
      :id,
      :name,
      :meeting_room_count,
      :custom_corp_url,
      :custom_corp_domain,
      :abilities,
    ]

    attr_accessor(*Fields)
  end
end
