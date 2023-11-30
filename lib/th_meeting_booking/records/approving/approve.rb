module ThMeetingBooking::Records::Approving
  # 审批信息，示例数据如下
  # ```JSON
  # {
  #   "id": "TAT9Z87UPGbxQriuVL1dHQ",
  #   "subject": "test abc",
  #   "ownerName": "马保险",
  #   "ownerSex": "null",
  #   "meetingInfra": "[]",
  #   "ownerDeptName": "无部门",
  #   "ownerUserEmail": "maobaoxian@test.com",
  #   "bookingUserId": "Pi8u64x3jCcvh7MSQpwNwQ",
  #   "bookingUsernamePinYin": "Ma Baoxian",
  #   "bookingUserEmail": "maobaoxian@test.com",
  #   "bookingUserName": "马保险",
  #   "bookingUserShowName": "马保险",
  #   "beginTime": "2022-09-05 14:00:00",
  #   "endTime": "2022-09-05 16:00:00",
  #   "roomId": "EsvdH83Y4GW2PGH39e9p2k",
  #   "roomName": "第二会议室",
  #   "officeAreaId": "9KgMd2zPrFxzxaid1TSsQA",
  #   "officeAreaName": "默认楼层",
  #   "templateType": "",
  #   "status": "APPROVE",
  #   "workflow": "APPROVE",
  #   "statusLabel": "待审批",
  #   "members": [
  #     {
  #       "id": "Pi8u64x3jCcvh7MSQpwNwQ",
  #       "name": "马保险",
  #       "namePinyin": "Ma Baoxian",
  #       "nickName": "Ma Baoxian",
  #       "email": "maobaoxian@test.com",
  #       "loginName": "maobaoxian@test.com",
  #       "corpId": "5HqXn3Bpgits6WVbRjXpVY",
  #       "corpName": "双杰测试",
  #       "deptId": "0",
  #       "deptName": "无部门",
  #       "headImgUrl": "https://a.cdn6.cn/assets/default-head.jpg",
  #       "balanceAmount": 0,
  #       "corpPlatform": "WXMP",
  #       "status": "ACTIVE",
  #       "labelName": "马保险",
  #       "labelDeptName": "无部门",
  #       "joinAt": "",
  #       "checkAt": ""
  #     }
  #   ],
  #   "approveUsers": [
  #     {
  #       "id": "LkTkWPMjSLG56SdZ8WXVGM",
  #       "name": "段敏",
  #       "namePinyin": "Duan Min",
  #       "position": "机械技术工程师",
  #       "jobNumber": "20110191",
  #       "nickName": "Duan Min",
  #       "loginName": "20110191",
  #       "mobile": "18614095268",
  #       "status": "ACTIVE",
  #       "upstreamId": "57d0fadfe4b0a473949a5e5a",
  #       "labelName": "段敏",
  #       "joinAt": "",
  #       "checkAt": ""
  #     }
  #   ],
  #   "email": "maobaoxian@test.com",
  #   "parentMeeting": {
  #     "id": "K2qA5DcLUHsSn2Sc6oLKJ4",
  #     "subject": "test abc",
  #     "ownerId": "Pi8u64x3jCcvh7MSQpwNwQ",
  #     "ownerName": "马保险",
  #     "clientType": "WEBAPP",
  #     "ownerDeptName": "无部门",
  #     "ownerUserNamePinYin": "Ma Baoxian",
  #     "ownerUserEmail": "maobaoxian@test.com",
  #     "bookingUserId": "Pi8u64x3jCcvh7MSQpwNwQ",
  #     "bookingUsernamePinYin": "Ma Baoxian",
  #     "bookingUserEmail": "maobaoxian@test.com",
  #     "bookingUserName": "马保险",
  #     "bookingUserShowName": "马保险",
  #     "beginTime": "2022-09-05 11:00:00",
  #     "endTime": "2022-09-05 13:00:00",
  #     "longTimeUse": false,
  #     "duration": 120,
  #     "roomId": "EsvdH83Y4GW2PGH39e9p2k",
  #     "roomName": "第二会议室",
  #     "officeAreaId": "9KgMd2zPrFxzxaid1TSsQA",
  #     "officeAreaName": "默认楼层",
  #     "roomNeedApproved": true,
  #     "templateType": "",
  #     "customFormIds": [
  #       "585473167608733696"
  #     ],
  #     "roomType": "ROOM",
  #     "status": "APPROVE",
  #     "workflow": "APPROVE",
  #     "statusLabel": "待审批",
  #     "notPublic": false,
  #     "needCheckin": true,
  #     "checkedStatus": "N",
  #     "meetingRepeatType": "NONE",
  #     "meetingType": "STANDARD",
  #     "busyCssName": "busy busy-for-me",
  #     "createdAt": "2022-09-02 15:27:04",
  #     "updatedAt": "2022-09-02 15:27:43",
  #     "beforeNotify": false,
  #     "abilities": [
  #       "cancel"
  #     ]
  #   },
  #   "createdAt": "2022-09-02 15:27:42",
  #   "meetingFiles": [],
  #   "beforeNotify": false,
  #   "facilityNames": [],
  #   "abilities": [
  #     "cancel"
  #   ]
  # }
  # ```
  class Approve < ThMeetingBooking::Records::Base
    Fields = [
      :id,
      :subject,
      :owner_name,
      :owner_sex,
      :meeting_infra,
      :owner_dept_name,
      :owner_user_email,
      :booking_user_id,
      :booking_username_pin_yin,
      :booking_user_email,
      :booking_user_name,
      :booking_user_show_name,
      :begin_time,
      :end_time,
      :room_id,
      :room_name,
      :office_area_id,
      :office_area_name,
      :template_type,
      :status,
      :workflow,
      :status_label,
      :members,
      :approve_users,
      :email,
      :parent_meeting,
      :created_at,
      :meeting_files,
      :before_notify,
      :facility_names,
      :abilities,
    ]

    attr_accessor(*Fields)

    def members=(value)
      if value.is_a?(Array)
        @members = value.map { |item| Member.new(item) }
      else
        @members = nil
      end
    end

    def approve_users=(value)
      if value.is_a?(Array)
        @approve_users = value.map { |item| ApproveUser.new(item) }
      else
        @approve_users = nil
      end
    end

    def parent_meeting=(value)
      if value.is_a?(Hash)
        @parent_meeting = ThMeetingBooking::Records::Booking::Meeting.new(value)
      else
        @parent_meeting = nil
      end
    end
  end
end
