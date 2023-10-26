class MemberProfile < ApplicationRecord
  belongs_to :member, class_name: "Member", foreign_key: "member_id"

  before_save :set_default_name, if: Proc.new { |profile| profile.name.blank? }
  before_save :set_default_company, if: Proc.new { |profile| profile.company.blank? }
  before_save :set_default_department, if: Proc.new { |profile| profile.department.blank? }
  before_save :set_default_position, if: Proc.new { |profile| profile.position.blank? }
  before_save :set_default_major, if: Proc.new { |profile| profile.major.blank? }
  before_save :set_default_mobile, if: Proc.new { |profile| profile.mobile.blank? }

  after_save :update_principal_name, if: Proc.new { |profile| profile.saved_change_to_name? }

  def self.service_columns = %i(name company department position major mobile remark)

  private
  def set_default_name
    return unless member.principal.present? && member.principal.respond_to?(:name) && member.principal.name.present?
    self.name = member.principal.name
  end

  def set_default_company
    return unless member.principal.present? && member.principal.respond_to?(:company) && member.principal.company.present?
    self.company = member.principal.company
  end

  def set_default_department
    return unless member.principal.present? && member.principal.respond_to?(:department) && member.principal.department.present?
    self.department = member.principal.department
  end

  def set_default_position
    return unless member.principal.present? && member.principal.respond_to?(:title) && member.principal.title.present?
    self.position = member.principal.title
  end

  def set_default_mobile
    return unless member.principal.present? && member.principal.respond_to?(:mobile) && member.principal.mobile.present?
    self.mobile = member.principal.mobile
  end

  def set_default_major
    return unless member.principal.present? && (/@thape\.com\.cn$/ === member.principal.mail)
    staff = member.principal.staff
    return unless staff.present? && staff.profession.present?
    self.major = staff.profession
  end

  def update_principal_name
    return unless member.principal.present? && self.name.present? && member.principal.name != self.name
    member.principal.update_columns(lastname: self.name)
  end
end
