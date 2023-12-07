module OpenProject::ThMeetings
  module Patches::MeetingsControllerPatch
    def self.included(base) # :nodoc:
      base.class_eval do
        private
        def meeting_params
          params.require(:meeting).permit(:title, :th_meeting_upstream_room_id, :start_time, :duration, :start_date, :start_time_hour,
                                          participants_attributes: %i[email name invited attended user user_id meeting id])
        end
      end
    end
  end
end
