module OpenProject::ThMembers
  module Patches::MemberPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_one :profile, class_name: "MemberProfile", foreign_key: "member_id"

        accepts_nested_attributes_for :profile

        after_save :set_profile

        attr_accessor :company, :position, :remark
      end
    end

    module InstanceMethods
      def set_profile
        profile = self.profile || MemberProfile.new(member_id: self.id)
        profile.company = company if company.present?
        profile.position = position if position.present?
        profile.remark = remark if remark.present?
        profile.save! if profile.changed?
      end
    end
  end
end
