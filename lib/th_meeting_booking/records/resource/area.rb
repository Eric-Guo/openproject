module ThMeetingBooking::Records::Resource
  # 区域信息，示例数据如下
  # ```JSON
  # {
  #   "id": "9KgMd2zPrFxzxaid1TSsQA", //主键
  #   "name": "默认楼层", //名称
  #   "level": "FLOOR",
  #   "shortName": "默认楼层",
  #   "showOrder": 1,
  #   "supportRoomTypes": [
  #     "ROOM"
  #   ],
  #   "validRoomCount": 3,
  #   "abilities": [
  #     "booking"
  #   ]
  # }
  # ```
  class Area < ThMeetingBooking::Records::Base
    Fields = [
      :id, # 主键
      :name, # 名称
      :level,
      :short_name,
      :show_order,
      :support_room_types,
      :valid_room_count,
      :abilities,
    ]

    attr_accessor(*Fields)
  end
end
