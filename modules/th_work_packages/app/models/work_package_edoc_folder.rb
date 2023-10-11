class WorkPackageEdocFolder < ApplicationRecord
  belongs_to :work_package

  has_many :files, class_name: "WorkPackageEdocFile", foreign_key: "folder_id", primary_key: "folder_id"

  after_create_commit :create_publish_url

  def publish_url
    return nil unless publish_code.present?
    Edoc::Helpers.publish_url(publish_code)
  end

  def folder_url
    Edoc::Helpers.folder_url(folder_id)
  end

  def create_publish_url
    ThWorkPackages::PublishEdocFolderJob.perform_later(id)
  end
end
