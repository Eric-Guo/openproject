# 人员信息，示例数据如下
# ```JSON
# {
#   "id": "SmmksVzcsa6cyhnZoGNJEt",
#   "loginName": "zhang001",
#   "name": "张三2",
#   "namePinyin": "Zhang San2",
#   "nickName": "",
#   "headImgUrl": "https://a.cdn6.cn/assets/default-head.jpg",
#   "email": "zhang001@test.com",
#   "mobile": "15026101010",
#   "isAnonymous": false,
#   "disableBooking": false,
#   "abilities": []
# }
# ```
class ThMeetingBooking::Records::Organization::User < ThMeetingBooking::Records::Base
  Fields = [
    :id,
    :login_name,
    :name,
    :name_pinyin,
    :nick_name,
    :head_img_url,
    :email,
    :mobile,
    :is_anonymous,
    :disable_booking,
    :abilities,
  ]

  attr_accessor(*Fields)
end
