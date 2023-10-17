class WorkPackageEdocFiles::SetAttributesService < BaseServices::SetAttributes
  private

  def set_attributes(attributes)
    if edoc_file.new_record?
      edoc_file.user_id = user.id if user.present?
      set_default_attributes(attributes)
    end
  end

  def edoc_file
    model
  end

  def set_default_attributes(attributes)
    set_default_file_fields(attributes)
    set_default_upload_fields(attributes)
  end

  def get_uniq_file_name(file_name, folder_id, index = 1)
    if Edoc::Files.id_by_name(file_name, folder_id).present?
      basename = File.basename(file_name, '.*')
      extname = File.extname(file_name)

      basename.gsub!(/\(\d+\)$/, '') unless index == 1

      get_uniq_file_name("#{basename}(#{index})#{extname}", folder_id, index + 1)
    else
      file_name
    end
  end

  def set_default_file_fields(attributes)
    return unless attributes[:file_name].present? && attributes[:folder_id].present?

    edoc_file.folder_id = attributes[:folder_id]

    edoc_file.file_name = get_uniq_file_name(attributes[:file_name], attributes[:folder_id])

    edoc_file.content_type = attributes[:content_type].presence || default_content_type
  end

  def set_default_upload_fields(attributes)
    file_size = get_file_size(attributes)

    return unless file_size > 0

    edoc_file.md5 = attributes[:md5]

    edoc_file.file_size = file_size

    edoc_file.chunks = calc_chunks(file_size, max_block_length)

    edoc_file.chunk_size = max_block_length
  end

  def get_file_size(attributes)
    if attributes[:file_size].instance_of?(Integer)
      attributes[:file_size]
    elsif attributes[:file_size].class == String && /\d+/ =~ attributes[:file_size]
      attributes[:file_size].to_i
    else
      0
    end
  end

  def max_block_length
    1024 * 1024 * 5
  end

  def calc_chunks(file_size, block_size)
    (file_size.to_f / block_size).ceil
  end

  def default_content_type
    'application/octet-stream'
  end
end
