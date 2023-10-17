class WorkPackageEdocFile < ApplicationRecord
  belongs_to :folder, class_name: "WorkPackageEdocFolder", foreign_key: "folder_id", primary_key: "folder_id"

  belongs_to :user

  before_create :edoc_start_upload

  before_destroy :edoc_remove_file

  def publish_preview_url
    return nil unless status == 1 && folder.publish_code.present?

    Edoc::Helpers.publish_preview_url(folder.publish_code, file_id)
  end

  def preview_url
    Edoc::Helpers.preview_url(file_id)
  end

  def upload_chunk(chunk_file, chunk_index)
    if status == 0
      res = Edoc::Files.chunk_upload(
        chunk_file.path,
        upload_id:,
        region_hash:,
        region_id:,
        region_type:,
        region_url:,
        file_name:,
        file_size:,
        md5:,
        chunks:,
        chunk: chunk_index,
        chunk_size:,
        block_size: chunk_file.size,
      )
      if res[:second_pass]
        update(status: 1)
      end
    end

    self
  end

  private

  def edoc_start_upload
    result = Edoc::Files.start_upload(
      folder_id:,
      file_name:,
      file_size:,
      content_type:,
      md5:,
      file_mode: 'UPLOAD',
      file_id: 0,
      file_path: '',
      file_code: '',
      remark: ''
    )

    self.file_id = result[:file_id]

    self.upload_id = result[:upload_id]

    self.file_ver_id = result[:file_ver_id]

    self.region_hash = result[:region_hash]

    self.region_id = result[:region_id]

    self.region_type = result[:region_type]

    self.region_url = result[:region_url]

    self.status = 1 if result[:second_pass]
  end

  def edoc_remove_file
    begin
      Edoc::Files.remove(file_id)
    rescue
    end
  end
end
