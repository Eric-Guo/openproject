module ThMeetingBooking::Apis
  class Resource < Base
    # 获取区域列表。
    # 区域：指可预订资源所属的位置区域，如办公区域、楼层、地区等，可灵活设置。
    # @return [Array[ThMeetingBooking::Records::Resource::Area]]
    def self.areas
      result = ThMeetingBooking::Request.new.get('areas')
      result[:data].map { |item| ThMeetingBooking::Records::Resource::Area.new(item) }
    end

    # 资源列表
    # 获取可预订的资源列表。
    # 资源：可给人在指定时间使用的资源，如会议室等。
    # @param room_type: [String] 资源类型，默认是ROOM，会议室
    # @param begin_time: [String] 开始时间；begin_time和end_time需要同时提供，提供后会返回isBusy字段，2024-01-01 00:00
    # @param end_time: [String] 结束时间；begin_time和end_time需要同时提供，提供后会返回isBusy字段，2024-01-31 12:00
    # @param showBusy: [Boolean] 占用过滤；true：只显示占用, false: 只显示空闲，空值表示不过滤
    # @return [ThMeetingBooking::Records::Resource::MeetingRoomList]
    def self.meeting_rooms(room_type: 'ROOM', begin_time: nil, end_time: nil, show_busy: nil)
      params = {
        roomType: room_type,
        begin: begin_time,
        end: end_time,
        showBusy: show_busy
      }
      result = ThMeetingBooking::Request.new.get('meeting-rooms', params:)
      ThMeetingBooking::Records::Resource::MeetingRoomList.new(result)
    end

    # 同步资源
    # 同步资源。按upstreamId，如果存在对应的资源，则按名字等参数修改资源信息。 如果不存在对应upstreamId的资源，则创建资源。
    # @param name: [String] 名称
    # @param upstream_id: [String] 业务系统部门ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param room_type: [String] 资源类型，默认是ROOM，会议室
    # @return [ThMeetingBooking::Records::Resource::MeetingRoom]
    def self.sync_meeting_rooms(name:, upstream_id:, room_type: 'ROOM')
      params = {
        roomType: room_type,
      }
      data = {
        name:,
        upstreamId: upstream_id,
      }
      result = ThMeetingBooking::Request.new.put('sync-meeting-rooms', params:, data:)
      ThMeetingBooking::Records::Resource::MeetingRoom.new(result[:data])
    end

    # 同步删除资源
    # 同步删除资源。按upstreamId，如果存在deleted=1参数，则同步删除此资源。
    # @param name: [String] 名称
    # @param upstream_id: [String] 业务系统部门ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param room_type: [String] 资源类型，默认是ROOM，会议室
    # @return [ThMeetingBooking::Records::Resource::MeetingRoom]
    def self.remove_sync_meeting_room(name:, upstream_id:, room_type: 'ROOM')
      params = {
        roomType: room_type,
      }
      data = {
        name:,
        upstreamId: upstream_id,
        deleted: 1,
      }
      result = ThMeetingBooking::Request.new.put('sync-meeting-rooms', params:, data:)
      ThMeetingBooking::Records::Resource::MeetingRoom.new(data)
    end
  end
end
