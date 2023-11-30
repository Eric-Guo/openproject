module ThMeetingBooking::Records::Booking
  # 会议室会议信息，示例数据如下
  # ```JSON
  # {
  #   "id": "C631VzoyZo5AE3azuKLYkg",
  #   "name": "第一会议室",
  #   "shortName": "第一会议室",
  #   "officeAreaId": "9KgMd2zPrFxzxaid1TSsQA",
  #   "officeArea": "默认楼层",
  #   "location": "",
  #   "qrCodeUrl": "https://wxmp.tlq.v-vip.cn/api/room/qrcode/C631VzoyZo5AE3azuKLYkg.png",
  #   "qrCodeTitle": "微信扫码预订",
  #   "disabled": false,
  #   "currentStatus": "FREE",
  #   "capacity": 0,
  #   "showOrder": 1,
  #   "freeOfCharge": true,
  #   "needApproved": false,
  #   "k2Approved": false,
  #   "roomCategoryIds": [],
  #   "needInterval": false,
  #   "hideWhenForbid": false,
  #   "notifyServiceAdmin": false,
  #   "pricePerHour": 80,
  #   "defaultPricePerHour": 80,
  #   "facilities": [],
  #   "allowRoles": [],
  #   "type": "ROOM",
  #   "isFavorite": false,
  #   "extras": [],
  #   "abilities": [
  #     "checkin"
  #   ]
  # }
  # ```
  class DayMeeting < ThMeetingBooking::Records::Base
    Fields = [
      :id,
      :name,
      :short_name,
      :office_area_id,
      :office_area,
      :location,
      :qr_code_url,
      :qr_code_title,
      :disabled,
      :current_status,
      :capacity,
      :show_order,
      :free_of_charge,
      :need_approved,
      :k2_approved,
      :room_category_ids,
      :need_interval,
      :hide_when_forbid,
      :notify_service_admin,
      :price_per_hour,
      :default_price_per_hour,
      :facilities,
      :allow_roles,
      :type,
      :is_favorite,
      :extras,
      :abilities,
    ]

    attr_accessor(*Fields)
  end
end
