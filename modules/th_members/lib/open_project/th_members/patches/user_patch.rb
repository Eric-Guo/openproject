module OpenProject::ThMembers
  module Patches::UserPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        before_create :set_th_profile

        after_save :update_member_profiles, if: Proc.new { |user| user.saved_change_to_last_login_on? \
          || (user.respond_to?(:lastname) && user.saved_change_to_lastname?) \
          || (user.respond_to?(:company) && user.saved_change_to_company?) \
          || (user.respond_to?(:department) && user.saved_change_to_department?) \
          || (user.respond_to?(:title) && user.saved_change_to_title?) \
          || (user.respond_to?(:mobile) && user.saved_change_to_mobile?)
        }
      end
    end

    module InstanceMethods
      def set_th_profile
        return unless /@thape\.com\.cn$/ === self.mail

        staff = Cybros::User.active.where(email: self.mail).first
        return unless staff.present?

        self.lastname = staff.chinese_name
        self.firstname = self.mail.sub(/@thape\.com\.cn$/, '')
        self.mobile = staff.mobile

        position = staff.positions.first
        return unless position.present?

        self.title = position.name

        department = position.department
        return unless department.present?

        self.company = department.company_name
        self.department = department.name
      end

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
