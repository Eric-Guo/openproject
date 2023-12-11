module ThMeetingBooking::Records::Resource
  class MeetingRoomList < ThMeetingBooking::Records::Base
    Fields = [
      :data,
      :total_count,
    ]

    attr_accessor(*Fields)

    def data=(value)
      if value.is_a?(Array)
        @data = sort_data(value.map { |item| MeetingRoom.new(item) })
      else
        @data = nil
      end
    end

    private
    def sort_data(data)
      data.group_by(&:office_area).sort.map { |_,items| items.sort_by(&:show_order) }.flatten
    end
  end
end
