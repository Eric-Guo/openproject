module ThMeetingBooking::Apis
  class Booking < Base
    # 指定日期的会议信息
    # 按参数查询会议列表
    # @param start_date: [String] 开始日期，格式 yyyy-MM-dd, 不填写就是当天
    # @param end_date: [String] 结束日期，格式 yyyy-MM-dd, 如不填则使用start的值
    # @param subject: [String]
    # @param room_id: [String]
    # @return [ThMeetingBooking::Records::Booking::MeetingList]
    def self.meetings(start_date: nil, end_date: nil, subject: nil, room_id: nil)
      params = {
        start: start_date,
        end: end_date,
        subject:,
        roomId: room_id,
      }
      result = ThMeetingBooking::Request.new.get('meetings', params:)
      ThMeetingBooking::Records::Booking::MeetingList.new(result)
    end

    # 指定日期的会议室会议信息
    # @param start_date: [String] 开始日期，格式 yyyy-MM-dd, 不填写就是当天
    # @param end_date: [String] 结束日期，格式 yyyy-MM-dd, 如不填则使用start的值
    # @return [Array[ThMeetingBooking::Records::Booking::DayMeeting]]
    def self.day_meetings(start_date: nil, end_date: nil)
      params = {
        start: start_date,
        end: end_date,
      }
      result = ThMeetingBooking::Request.new.get('day-meetings', params:)
      result[:data].map { |item| ThMeetingBooking::Records::Booking::DayMeeting.new(item) }
    end

    # 获取会议信息详情
    # 按ID读取会议详情
    # @param id [String]
    # @return [ThMeetingBooking::Records::Booking::Meeting]
    def self.meeting(id)
      result = ThMeetingBooking::Request.new.get("meetings/#{id}")
      ThMeetingBooking::Records::Booking::Meeting.new(result[:data])
    end

    # 同步预订信息
    # 同步预订信被同步预订信息。 基于upstreamId(业务系统的预订ID），按时间、主题、资源同步。
    # 如果目标资源和时间有其它的预订，也能正常写入，需要业务系统保证无重复预订。
    # @param upstream_id: [String] 业务系统预订ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param upstream_room_id: [String] 业务系统资源ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param booking_user_id: [String] 业务系统人员ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param booking_user_name: [String] 预订人姓名，如果不存在对应业务系统人员ID，会自动建立，所以姓名是必填。
    # @param booking_user_email: [String] 预订人邮箱
    # @param booking_user_phone: [String] 预订人电话
    # @param subject: [String] 预订主题
    # @param content: [String] 预订内容
    # @param begin_time: [String] 开始时间，格式：YYYY-MM-DD HH:mm:ss
    # @param end_time: [String] 结束时间，格式：YYYY-MM-DD HH:mm:ss
    # @param members: [Array[Hash{user_id=>String,name=>String,mail_address=>String}]] 参会人列表
    # @param members.user_id: [String] 业务系统人员ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param members.name: [String] 姓名
    # @param members.mail_address: [String] 邮箱
    # @param members.type: [String] 人员类型，访客=visitor，其他不传该字段
    # @return [ThMeetingBooking::Records::Booking::Meeting]
    def self.sync_meetings(
      upstream_id:,
      upstream_room_id:,
      booking_user_id:,
      booking_user_name:,
      booking_user_email: nil,
      booking_user_phone: nil,
      subject:,
      content: nil,
      begin_time:,
      end_time:,
      members:
    )
      data = {
        upstream_id:,
        upstream_room_id:,
        booking_user_id:,
        booking_user_name:,
        booking_user_email:,
        booking_user_phone:,
        subject:,
        content:,
        begin_time:,
        end_time:,
        members:
      }.deep_transform_keys { |key| key.to_s.camelize(:lower).to_sym }
      result = ThMeetingBooking::Request.new.post('book-meetings', data:)

      ThMeetingBooking::Records::Booking::Meeting.new(result[:data])
    end

    # 同步删除预订信息
    # 同步预订信被同步预订信息。 基于upstreamId(业务系统的预订ID），按时间、主题、资源同步。
    # 如果目标资源和时间有其它的预订，也能正常写入，需要业务系统保证无重复预订。
    # @param upstream_id: [String] 业务系统预订ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param upstream_room_id: [String] 业务系统资源ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param booking_user_id: [String] 业务系统人员ID
    # @param booking_user_name: [String] 预订人姓名
    # @param booking_user_email: [String] 预订人邮箱
    # @param booking_user_phone: [String] 预订人电话
    # @param subject: [String] 预订主题
    # @param content: [String] 预订内容
    # @param begin_time: [String] 开始时间，格式：YYYY-MM-DD HH:mm:ss
    # @param end_time: [String] 结束时间，格式：YYYY-MM-DD HH:mm:ss
    # @return [ThMeetingBooking::Records::Booking::Meeting]
    def self.remove_sync_meeting(
      upstream_id:,
      upstream_room_id:,
      booking_user_id:,
      booking_user_name:,
      booking_user_email:,
      booking_user_phone:,
      subject:,
      content:,
      begin_time:,
      end_time:
    )
      data = {
        upstream_id:,
        upstream_room_id:,
        booking_user_id:,
        booking_user_name:,
        booking_user_email:,
        booking_user_phone:,
        subject:,
        content:,
        begin_time:,
        end_time:,
        deleted: 1
      }.deep_transform_keys { |key| key.to_s.camelize(:lower).to_sym }
      result = ThMeetingBooking::Request.new.post('sync-meetings', data:)
      ThMeetingBooking::Records::Booking::Meeting.new(data)
    end

    # 取消会议信息
    # 按ID取消会议。 会议需要没有开始，开始后的会议不能取消。
    # @param id [String] 会议ID，例如: 2s4wtBQesFdczpwZzSo1QZ
    # @param reason: [String] 取消原因
    # @return [ThMeetingBooking::Records::Booking::Meeting]
    def self.cancel_meeting(id, reason:)
      data = { cancelReason: reason }
      result = ThMeetingBooking::Request.new.post("meetings/#{id}/cancel", data:)
      ThMeetingBooking::Records::Booking::Meeting.new(result[:data])
    end

    # 提前结束会议
    # 按ID提前结束会议。
    # 会议需要已经开始，且没有结束。
    # @param id [String] 会议ID，例如: 2s4wtBQesFdczpwZzSo1QZ
    # @return [ThMeetingBooking::Records::Booking::Meeting]
    def self.abort_meeting(id)
      result = ThMeetingBooking::Request.new.post("meetings/#{id}/finish")
      ThMeetingBooking::Records::Booking::Meeting.new(result[:data])
    end
  end
end
