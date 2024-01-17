module OpenProject::ThMeetings
  module Patches::MeetingPatch
    TH_MEETING_FIELDS = [
      :upstream_area_id, :upstream_area_name,
      :upstream_room_id, :upstream_room_name,
      :content,
    ]

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_one :th_meeting

        validate :validate_th_meeting_room

        validate :validate_th_meeting_time

        after_save :create_or_update_th_meeting

        after_destroy_commit do
          next unless self.th_meeting.present?

          if self.th_meeting.begin_time.to_time > Time.now
            ThMeetings::CancelThMeetingBookingJob.perform_later(self.id)
          else
            ThMeetings::RemoveThMeetingBookingJob.perform_later(self.id)
          end
        end

        attr_accessor(*TH_MEETING_FIELDS.map{ |field| "th_meeting_#{field}".to_sym })

        TH_MEETING_FIELDS.each do |field|
          method_name = "th_meeting_#{field}"

          define_method(method_name) do
            value = instance_variable_get("@#{method_name}")
            if value.nil?
              self.th_meeting&.send(field)
            else
              value
            end
          end

          define_method("#{method_name}=") do |value|
            instance_variable_set("@#{method_name}", value)

            self.th_meeting&.send("#{field}=", value)
          end
        end

        private
        def validate_th_meeting_room
          if self.th_meeting_upstream_room_id.present?
            rooms = ThMeetingBooking::Apis::Resource.meeting_rooms
            room = rooms.data.detect { |room| room.id == self.th_meeting_upstream_room_id }
            if room.nil?
              errors.add(:th_meeting_upstream_room_id, :invalid)
            else
              self.th_meeting_upstream_area_id = room.office_area_id
              self.th_meeting_upstream_area_name = room.office_area
              self.th_meeting_upstream_room_name = room.name

              self.location = [room.office_area, room.name].compact.join(' - ')
            end
          else
            self.th_meeting_upstream_area_id = ''
            self.th_meeting_upstream_area_name = ''
            self.th_meeting_upstream_room_name = ''

            self.location = ''
          end
        end

        def validate_th_meeting_time
          available_rooms = ThMeeting.available_rooms(
            start_date_time: self.start_date_time,
            end_date_time: self.end_date_time,
            th_meeting_id: self.th_meeting_id
          )

          unless available_rooms.any? { |room| room.id == self.th_meeting_upstream_room_id }
            errors.add(:start_time, :occupied)
          end
        end

        def create_or_update_th_meeting
          return if new_record?

          th_meeting = self.th_meeting || ThMeeting.new(meeting: self, upstream_id: self.th_meeting_upstream_id)

          th_meeting.upstream_area_id = self.th_meeting_upstream_area_id.to_s

          th_meeting.upstream_area_name = self.th_meeting_upstream_area_name.to_s

          th_meeting.upstream_room_id = self.th_meeting_upstream_room_id.to_s

          th_meeting.upstream_room_name = self.th_meeting_upstream_room_name.to_s

          th_meeting.booking_user_id = self.author.mail.to_s
          th_meeting.booking_user_name = self.author.name.to_s
          th_meeting.booking_user_email = self.author.mail.to_s
          th_meeting.booking_user_phone = self.author.mobile.to_s
          th_meeting.subject = self.title.to_s

          th_meeting.content = self.th_meeting_content.to_s

          th_meeting.begin_time = self.start_time.strftime('%Y-%m-%d %H:%M:%S')
          th_meeting.end_time = self.end_time.strftime('%Y-%m-%d %H:%M:%S')

          members = self.participants.map do |participant|
            member = {
              user_id: participant.user.mail.to_s,
              name: participant.user.name.to_s,
              mail_address: participant.user.mail.to_s,
            }
            unless member[:mail_address].end_with?('@thape.com.cn')
              member[:type] = 'visitor'
            end
            member
          end

          th_meeting.members = members

          th_meeting.save
        end
      end
    end

    module InstanceMethods
      def attributes=(attrs)
        unless attrs.is_a?(Hash)
          raise ArgumentError.new("When assigning attributes, you must pass a hash as an argument, #{attrs.class} passed.")
        end

        sym_attrs = attrs.symbolize_keys

        record_keys = self.attributes.keys.map(&:to_sym)
        record_attrs = sym_attrs.select { |key| record_keys.include?(key) }

        if record_attrs.present?
          super(record_attrs)
        end

        TH_MEETING_FIELDS.each do |field|
          method_name = "th_meeting_#{field}".to_sym

          if sym_attrs.include?(method_name)
            self.send("#{method_name}=", sym_attrs[method_name])
          end
        end

        attrs
      end

      def th_meeting_id
        self.th_meeting&.th_meeting_id
      end

      def th_meeting_upstream_id
        unless new_record?
          ThMeetingBooking::Helpers.upstream_id("plm_#{id}")
        end
      end

      def th_meeting_content_show
        th_meeting_content.presence || '-'
      end

      def location
        [self.th_meeting_upstream_area_name, self.th_meeting_upstream_room_name].compact.join(' - ')
      end

      def end_date
        end_time.to_date.iso8601
      end

      def end_month
        end_time.month
      end

      def end_year
        end_time.year
      end

      def start_date_time
        start_time.strftime('%Y-%m-%d %H:%M:%S')
      end

      def end_date_time
        end_time.strftime('%Y-%m-%d %H:%M:%S')
      end
    end
  end
end
