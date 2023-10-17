module WorkPackageEdocFiles
  class BaseContract < ::ModelContract
    include AssignableValuesContract

    attribute :folder_id
    attribute :file_id
    attribute :file_name
    attribute :upload_id
    attribute :md5
    attribute :content_type
    attribute :file_size
    attribute :file_ver_id
    attribute :region_hash
    attribute :region_id
    attribute :region_type
    attribute :region_url
    attribute :chunks
    attribute :chunk_size
    attribute :status
    attribute :user

    validate :validate_folder_id

    validate :validate_file_name

    validate :validate_md5

    validate :validate_file_size

    def initialize(edoc_file, user, options: {})
      super
    end

    private

    def validate_folder_id
      if model.folder_id.blank?
        errors.add :folder_id, :not_allow_empty
      end
    end

    def validate_file_name
      if model.file_name.blank?
        errors.add :file_name, :not_allow_empty
      end
    end

    def validate_md5
      if model.md5.blank?
        errors.add :md5, :not_allow_empty
      elsif !valid_md5?(model.md5)
        errors.add :md5, :invalid
      end
    end

    def validate_file_size
      if model.file_size.blank? || model.file_size <= 0
        errors.add :file_size, :not_allow_empty
      end
    end

    def valid_md5?(str)
      /^[0-9a-f]{32}$/ === str
    end
  end
end
