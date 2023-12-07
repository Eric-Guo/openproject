module OpenProject::ThNotifications
  module Patches::NotificationPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        after_create :send_to_wx
      end
    end

    module InstanceMethods
      def send_to_wx
        ThNotifications::SendToWxJob.perform_later(id)
        ThNotifications::SendToWxWorkJob.perform_later(id)
      end
    end
  end
end
