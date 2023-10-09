class WorkPackageEdocFolder < ApplicationRecord
  belongs_to :work_package

  has_many :files, class_name: "WorkPackageEdocFile", foreign_key: "folder_id", primary_key: "folder_id"
end
