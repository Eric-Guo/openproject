module OpenProject::ThMembers
  module Patches::MemberPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_one :profile, class_name: "MemberProfile", foreign_key: "member_id"
      end
    end

    module InstanceMethods
    end
  end
end
