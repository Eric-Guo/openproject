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
      online_rooms = []
      offline_rooms = []
      data.each do |item|
        if item.online?
          online_rooms << item
        else
          offline_rooms << item
        end
      end
      online_rooms = online_rooms.group_by(&:office_area).sort.map { |_,items| items.sort_by(&:show_order) }.flatten
      offline_rooms = offline_rooms.group_by(&:office_area).sort.map { |_,items| items.sort_by(&:show_order) }.flatten
      [*online_rooms, *offline_rooms]
    end
  end
end
