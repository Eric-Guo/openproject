class WorkPackageEdocFolder < ApplicationRecord
  belongs_to :work_package

  has_many :files, class_name: "WorkPackageEdocFile", foreign_key: "folder_id", primary_key: "folder_id"

  after_create_commit :create_publish_url

  def create_publish_url
    ThWorkPackages::PublishEdocFolderJob.perform_later(id)
  end
end
