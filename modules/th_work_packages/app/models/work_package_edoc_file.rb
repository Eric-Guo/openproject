class WorkPackageEdocFile < ApplicationRecord
  belongs_to :folder, class_name: "WorkPackageEdocFolder", foreign_key: "folder_id", primary_key: "folder_id"
end
