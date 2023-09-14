module OpenProject::ThMembers
  module Patches::UserPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        after_save :update_member_profiles, if: Proc.new { |user| user.saved_change_to_last_login_on? }
      end
    end

    module InstanceMethods
      def update_member_profiles
        return unless self.members.present?

        self.members.each do |member|
          next unless member.respond_to?(:profile)

          profile = member.profile || MemberProfile.new(member_id: member.id)

          if profile.name.blank? && self.respond_to?(:name) && self.name.present?
            profile.name = self.name
          end

          if profile.company.blank? && self.respond_to?(:company) && self.company.present?
            profile.company = self.company
          end

          if profile.department.blank? && self.respond_to?(:department) && self.department.present?
            profile.department = self.department
          end

          if profile.position.blank? && self.respond_to?(:title) && self.title.present?
            profile.position = self.title
          end

          if profile.mobile.blank? && self.respond_to?(:mobile) && self.mobile.present?
            profile.mobile = self.mobile
          end

          profile.save
        end
      end
    end
  end
end
