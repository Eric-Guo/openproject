class WorkPackageEdocFile < ApplicationRecord
  belongs_to :folder, class_name: "WorkPackageEdocFolder", foreign_key: "folder_id", primary_key: "folder_id"

  def publish_preview_url
    return nil unless status == 1 && folder.publish_code.present?
    Edoc::Helpers.publish_preview_url(folder.publish_code, file_id)
  end

  def preview_url
    Edoc::Helpers.preview_url(file_id)
  end
end
