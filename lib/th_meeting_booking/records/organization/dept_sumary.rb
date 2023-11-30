module ThMeetingBooking::Records::Organization
  # 部门统计数据
  # ```JSON
  # {
  #   "userCount": 178, //组织内员工数
  #   "userCountWithNew": 178, //组织内员工数（包含未激活的用户）
  #   "abilities": []
  # }
  # ```
  class DeptSumary < ThMeetingBooking::Records::Base
    Fields = [
      :user_count, # 组织内员工数
      :user_count_with_new, # 组织内员工数（包含未激活的用户）
      :abilities,
    ]

    attr_accessor(*Fields)
  end
end
