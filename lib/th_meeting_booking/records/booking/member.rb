# 会议成员，示例数据如下
# ```JSON
# {
#   "id": "D5oU5GsWiE1mTYv2YWYKgn",
#   "name": "niuyan",
#   "namePinyin": "niuyan",
#   "jobNumber": "",
#   "nickName": "niuyan",
#   "email": "",
#   "loginName": "niuyan",
#   "mobile": "18220488316",
#   "corpId": "5HqXn3Bpgits6WVbRjXpVY",
#   "corpName": "双杰测试",
#   "deptId": "0",
#   "deptName": "无部门",
#   "headImgUrl": "https://a.cdn6.cn/assets/default-head.jpg",
#   "balanceAmount": 0,
#   "corpPlatform": "WXMP",
#   "status": "ACTIVE",
#   "upstreamId": "1391658928041947137",
#   "labelName": "niuyan",
#   "labelDeptName": "无部门",
#   "joinStatus": "Y",
#   "joinAt": "2021-11-15 11:19:52",
#   "checkinStatus": "N",
#   "checkAt": ""
# }
# ```
class ThMeetingBooking::Records::Booking::Member < ThMeetingBooking::Records::Base
  Fields = [
    :id,
    :name,
    :name_pinyin,
    :job_number,
    :nick_name,
    :email,
    :login_name,
    :mobile,
    :corp_id,
    :corp_name,
    :dept_id,
    :dept_name,
    :head_img_url,
    :balance_amount,
    :corp_platform,
    :status,
    :upstream_id,
    :label_name,
    :label_dept_name,
    :join_status,
    :join_at,
    :checkin_status,
    :check_at,
  ]

  attr_accessor(*Fields)
end
