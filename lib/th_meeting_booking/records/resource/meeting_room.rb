module ThMeetingBooking::Records::Resource
  # 资源信息，示例数据如下
  # ```JSON
  # {
  #   "id": "C631VzoyZo5AE3azuKLYkg", //主键
  #   "name": "第一会议室", //名称
  #   "shortName": "第一会议室", //资源短名称，用于部分显示场景
  #   "officeAreaId": "9KgMd2zPrFxzxaid1TSsQA", //所属办公区域ID
  #   "officeArea": "默认楼层", //所属办公区域名称
  #   "location": "", //位置
  #   "qrCodeUrl": "https://wxmp.tlq.v-vip.cn/api/room/qrcode/C631VzoyZo5AE3azuKLYkg.png",
  #   "qrCodeTitle": "微信扫码预订",
  #   "disabled": false, //是否禁用，true表示禁用
  #   "upstreamId": "2321", //业务系统部门ID。字符类型，如果业务系统是数字型ID，需要转成string
  #   "currentStatus": "FREE", //当前状态：FREE 空闲/BUSY 占用中
  #   "showOrder": 1,
  #   "freeOfCharge": true,
  #   "needApproved": false,
  #   "k2Approved": false,
  #   "roomCategoryIds": [],
  #   "needInterval": false,
  #   "hideWhenForbid": false,
  #   "notifyServiceAdmin": false,
  #   "facilities": [],
  #   "allowRoles": [],
  #   "type": "ROOM",
  #   "isFavorite": false,
  #   "abilities": [],
  #   "isBusy": true, //是否被占用
  # }
  # ```
  class MeetingRoom < ThMeetingBooking::Records::Base
    Fields = [
      :id, # 主键
      :name, # 名称
      :short_name, # 资源短名称，用于部分显示场景
      :office_area_id, # 所属办公区域ID
      :office_area, # 所属办公区域名称
      :location, # 位置
      :qr_code_url,
      :qr_code_title,
      :disabled, # 是否禁用，true表示禁用
      :upstream_id, # //业务系统部门ID。字符类型，如果业务系统是数字型ID，需要转成string
      :current_status, # 当前状态：FREE 空闲/BUSY 占用中
      :show_order,
      :free_of_charge,
      :need_approved,
      :k2_approved,
      :room_category_ids,
      :need_interval,
      :hide_when_forbid,
      :notify_service_admin,
      :facilities,
      :allow_roles,
      :type,
      :is_favorite,
      :abilities,
      :deleted,
      :is_busy,
      :busy_booking_ids,
    ]

    attr_accessor(*Fields)

    def online?
      self.office_area == '线上会议'
    end
  end
end
