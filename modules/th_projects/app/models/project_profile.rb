class ProjectProfile < ApplicationRecord
  belongs_to :project, class_name: "Project", foreign_key: "project_id"

  before_validation :convert_nil_to_empty_string

  validate :uniqueness_of_code_and_type_id

  def uniqueness_of_code_and_type_id
    return if type_id == 0 || code.blank?

    only_profile = if type_id == 0
      ProjectProfile.where.not(type_id: 0)
    else
      ProjectProfile.where(type_id:)
    end

    only_profile = only_profile.where(code:)
    only_profile = only_profile.where.not(id:) if id

    only_profile = only_profile.first

    errors.add(:code, :has_existed) if only_profile.present?
  end

  private

  def convert_nil_to_empty_string
    self.type_id ||= 0
    self.name ||= ''
    self.code ||= ''
    self.doc_link ||= ''
  end
end
