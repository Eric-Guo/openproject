class ProjectProfile < ApplicationRecord
  belongs_to :project, class_name: "Project", foreign_key: "project_id"

  validate :uniqueness_of_code_and_type_id

  def uniqueness_of_code_and_type_id
    only_profile = if type_id == 0
      ProjectProfile.where.not(type_id: 0)
    else
      ProjectProfile.where(type_id:)
    end
    only_profile = if code == ''
      only_profile.where.not(code: '')
    else
      only_profile.where(code:)
    end
    only_profile = only_profile.where.not(id:) if id

    only_profile = only_profile.first

    errors.add(:code, :has_existed) if only_profile.present?
  end
end
