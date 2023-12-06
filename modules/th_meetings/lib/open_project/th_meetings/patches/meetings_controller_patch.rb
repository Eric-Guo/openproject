module OpenProject::ThMeetings
  module Patches::MeetingsControllerPatch
    def self.included(base) # :nodoc:
      base.class_eval do
        private
        def convert_params
          # We do some preprocessing of `meeting_params` that we will store in this
          # instance variable.
          @converted_params = meeting_params.to_h

          if @converted_params[:th_meeting_upstream_room_id].present?
            rooms = ThMeetingBooking::Apis::Resource.meeting_rooms
            room = rooms.data.detect { |room| room.id == @converted_params[:th_meeting_upstream_room_id] }
            raise ArgumentError.new('Select a meeting room that is NOT FOUND') unless room.present?

            @converted_params[:th_meeting_upstream_area_id] = room.office_area_id
            @converted_params[:th_meeting_upstream_area_name] = room.office_area
            @converted_params[:th_meeting_upstream_room_name] = room.name

            @converted_params[:location] = [room.office_area, room.name].compact.join(' - ')
          end

          @converted_params[:duration] = @converted_params[:duration].to_hours
          # Force defaults on participants
          @converted_params[:participants_attributes] ||= {}
          @converted_params[:participants_attributes].each { |p| p.reverse_merge! attended: false, invited: false }
        end

        def meeting_params
          params.require(:meeting).permit(:title, :th_meeting_upstream_room_id, :start_time, :duration, :start_date, :start_time_hour,
                                          participants_attributes: %i[email name invited attended user user_id meeting id])
        end
      end
    end
  end
end
