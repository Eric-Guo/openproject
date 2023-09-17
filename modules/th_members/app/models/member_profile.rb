class MemberProfile < ApplicationRecord
  belongs_to :member, class_name: "Member", foreign_key: "member_id"

  before_save :set_default_name, if: Proc.new { |profile| profile.name.blank? }
  before_save :set_default_company, if: Proc.new { |profile| profile.company.blank? }
  before_save :set_default_department, if: Proc.new { |profile| profile.department.blank? }
  before_save :set_default_position, if: Proc.new { |profile| profile.position.blank? }
  before_save :set_default_mobile, if: Proc.new { |profile| profile.mobile.blank? }

  after_save :update_user_name, if: Proc.new { |profile| profile.saved_change_to_name? }

  def self.service_columns = %i(name company department position mobile remark)

  private
  def set_default_name
    return unless member.user.present? && member.user.respond_to?(:name) && member.user.name.present?
    self.name = member.user.name
  end

  def set_default_company
    return unless member.user.present? && member.user.respond_to?(:company) && member.user.company.present?
    self.company = member.user.company
  end

  def set_default_department
    return unless member.user.present? && member.user.respond_to?(:department) && member.user.department.present?
    self.department = member.user.department
  end

  def set_default_position
    return unless member.user.present? && member.user.respond_to?(:title) && member.user.title.present?
    self.position = member.user.title
  end

  def set_default_mobile
    return unless member.user.present? && member.user.respond_to?(:mobile) && member.user.mobile.present?
    self.mobile = member.user.mobile
  end

  def update_user_name
    return unless member.user.present? && self.name.present? && member.user.name != self.name
    member.user.update_columns(lastname: self.name)
  end
end
