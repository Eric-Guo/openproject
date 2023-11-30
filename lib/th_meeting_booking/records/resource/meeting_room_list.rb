module ThMeetingBooking::Records::Resource
  class MeetingRoomList < ThMeetingBooking::Records::Base
    Fields = [
      :data,
      :total_count,
    ]

    attr_accessor(*Fields)

    def data=(value)
      if value.is_a?(Array)
        @data = value.map { |item| MeetingRoom.new(item) }
      else
        @data = nil
      end
    end
  end
end
