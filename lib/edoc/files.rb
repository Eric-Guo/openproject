class Edoc::Files
  # 在文件夹中通过文件名查找file_id
  # @param file_name [String] - 文件名称
  # @param folder_id [Integer] - 文件夹ID
  # @return [Integer] - 文件ID，未找到返回nil
  def self.id_by_name(file_name, folder_id)
    path = '/api/services/File/IsExistFileInFolderByFileName'
    params = Edoc::Helpers.hash_with_token(folderId: folder_id, fileName: file_name)

    url = Edoc::Helpers.url(path, params)
    result = Edoc::Helpers.parse_response(HTTP.get(url))

    raise StandardError.new(result) unless result[:result] == 0

    return nil unless result[:data][:IsExist]

    result[:data][:FileId]
  end

  # 获取文件夹下的文件列表
  # @param folder_id [Integer] - 文件夹ID
  # @return [Array<Hash{folder_id=>Integer folder_name=>String}>]
  def self.list(folder_id)
    path = '/api/services/File/GetChildFileListByFolderId'
    params = Edoc::Helpers.hash_with_token(folderId: folder_id)

    url = Edoc::Helpers.url(path, params)
    result = Edoc::Helpers.parse_response(HTTP.get(url))

    raise StandardError.new(result) unless result[:result] == 0

    result[:data].map do |item|
      {
        file_id: item[:FileId],
        file_name: item[:FileName],
        ext_name: item[:FileExtName],
        size: item[:FileLastSize],
      }
    end
  end

  # 删除文件
  # @param file_ids [Array<Integer>] - 文件ID列表
  # @return [nil]
  def self.remove(*file_ids)
    path = '/api/services/Doc/RemoveFolderListAndFileList'
    headers = { 'Content-Type': 'application/json' }
    data = Edoc::Helpers.hash_with_token(FileIdList: file_ids)

    response = HTTP.headers(headers).post(Edoc::Helpers.url(path), json: data)
    result = Edoc::Helpers.parse_response(response)

    raise StandardError.new(result) unless result[:result] == 0

    result[:data]
  end

  # 启动上传
  # @param folder_id: [Integer] - 上传的文件夹ID
  # @param file_name: [String] - 文件名
  # @param file_size: [Integer] - 文件大小
  # @param content_type: [String] - 文件类型
  # @param file_mode: [String] - 更新版本或上传，UPLOAD/UPDATE
  # @param file_id: [Integer] - 文件ID，更新版本时必传
  # @param md5: [String] - 文件MD5指纹
  # @param file_path: [String] - 文件完整路径
  # @param file_code: [String] - 文件编码
  # @param remark: [String] - 备注
  # @return [Hash{file_id=>Integer file_ver_id=>Integer folder_id=>Integer region_hash=>String region_id=>Integer region_type=>String region_url=>String}]
  def self.start_upload(
    folder_id:,
    file_name:,
    file_size:,
    content_type: 'application/octet-stream',
    file_mode: 'UPLOAD',
    file_id: 0,
    md5: '',
    file_path: '',
    file_code: '',
    remark: ''
  )
    raise StandardError.new('文件夹ID不能为空') unless folder_id.present?
    raise StandardError.new('文件名不能为空') unless file_name.present?
    raise StandardError.new('文件大小不能为 0') unless file_size > 0
    raise StandardError.new('file_mode取值: UPDATE、UPLOAD') unless ['UPDATE', 'UPLOAD'].include?(file_mode)
    raise StandardError.new('更新版本时 file_id 不能为空') if file_mode == 'UPDATE' && file_id.blank?

    upload_id = SecureRandom.uuid

    path = '/WebCore?module=RegionDocOperationApi&fun=CheckAndCreateDocInfo'

    url = Edoc::Helpers.url(path)

    form_data = Edoc::Helpers.hash_with_token({
      folderId: folder_id,
      fileName: file_name,
      fileRemark: remark,
      size: file_size,
      type: content_type,
      attachType: 0,
      fullPath: file_path,
      code: file_code,
      masterFileId: 0,
      fileId: file_id,
      strategy: 'majorUpgrade',
      fileModel: file_mode,
      fileMd5: md5,
    })

    Rails.logger.tagged(upload_id) { |logger| logger.info '第一步 - 启动上传' }
    Rails.logger.tagged(upload_id) { |logger| logger.info url }
    Rails.logger.tagged(upload_id) { |logger| logger.info form_data }

    response = HTTP.post(url, form: form_data)

    Rails.logger.tagged(upload_id) { |logger| logger.info response.status }
    Rails.logger.tagged(upload_id) { |logger| logger.info response.body.to_s.force_encoding("UTF-8") }

    result = Edoc::Helpers.parse_response(response)

    raise StandardError.new(result) unless result[:result] == 0

    {
      md5:,
      file_size:,
      upload_id:,
      file_name:,
      file_id: file_mode == 'UPDATE' ? args[:file_id] : result[:data][:FileId],
      file_ver_id: result[:data][:FileVerId],
      folder_id: result[:data][:ParentFolderId],
      region_hash: result[:data][:RegionHash],
      region_id: result[:data][:RegionId],
      region_type: result[:data][:RegionType],
      region_url: result[:data][:RegionUrl],
      second_pass: result[:secondPass] == true || result[:secondPass] == 'true'
    }
  end

  # 分片上传
  # @param file [File] - 切片文件
  # @param upload_id: [String] - 上传文件ID
  # @param region_hash: [String] - 区域Hash
  # @param region_id: [Integer] - 区域Id
  # @param region_type: [Integer] - 区域类型，1：主区域，2：分区域
  # @param region_url: [Integer] - 区域站点地址，RegionType=1时，为空
  # @param file_name: [String] - 文件名
  # @param md5: [String] - 文件md5，用于判断是否秒传
  # @param file_size: [Integer] - 文件大小
  # @param chunks: [Integer] - 一共几块
  # @param chunk: [Integer] - 本次请求传入的是第几块下标从0开始
  # @param chunk_size: [Integer] - 分块大小
  # @param block_size: [Integer] - 本次请求传入的块大小
  # @return [Hash{upload_id=>String second_pass=>Boolean}]
  def self.chunk_upload(
    file,
    upload_id:,
    region_hash:,
    region_id:,
    region_type:,
    region_url:,
    file_name:,
    file_size:,
    md5:,
    chunks:,
    chunk:,
    chunk_size:,
    block_size:
  )
    raise StandardError.new('参数file的类型必须为File') unless file.is_a?(File)

    path = '/document/upload'
    host = region_type == 1 ? Edoc::Config.host : region_url
    url = Edoc::Helpers._url(host, path, Edoc::Helpers.hash_with_token)

    form_data = {
      uploadId: upload_id,
      regionHash: region_hash,
      regionId: region_id,
      fileName: file_name,
      fileMd5: md5,
      size: file_size,
      chunks: chunks,
      chunk: chunk,
      chunkSize: chunk_size,
      blockSize: block_size,
      file: HTTP::FormData::File.new(file.path),
    }

    Rails.logger.tagged(upload_id) { |logger| logger.info "第#{chunk + 1}块" }
    Rails.logger.tagged(upload_id) { |logger| logger.info url }
    Rails.logger.tagged(upload_id) { |logger| logger.info "分片大小: #{block_size}" }
    Rails.logger.tagged(upload_id) { |logger| logger.info form_data }

    response = HTTP.post(url, form: form_data)

    Rails.logger.tagged(upload_id) { |logger| logger.info response.status }
    Rails.logger.tagged(upload_id) { |logger| logger.info response.body.to_s.force_encoding("UTF-8") }

    result = Edoc::Helpers.parse_response(response)

    raise StandardError.new(result) if result[:status] == 'Error'
    raise StandardError.new('上传已取消') if result[:status] == 'Cancel'

    {
      upload_id:,
      second_pass: result[:status] == 'End' || result[:tag] == true || result[:tag] == 'true',
    }
  end

  # 上传文件
  # @param file [File] - 文件
  # @param folder_id: [Integer] - 上传的文件夹ID
  # @param file_name: [String] - 文件名
  # @param file_id: [Integer] - 文件ID，更新版本时必传
  # @param is_update: [Boolean] - 是否为更新版本
  # @param content_type: [String] - 文件类型
  # @param md5: [String] - 文件MD5指纹
  # @param file_path: [String] - 文件完整路径
  # @param file_code: [String] - 文件编码
  # @param remark: [String] - 备注
  # @return [Hash{upload_id=>Integer file_name=>String file_id=>Integer file_ver_id=>Integer folder_id=>Integer}]
  def self.upload(file, folder_id:, file_name:, **args)
    raise StandardError.new('参数file的类型必须为File') unless file.is_a?(File)

    content_type = args[:content_type] || MiniMime.lookup_by_filename(file)&.content_type || 'application/octet-stream'
    md5 = args[:md5] || Digest::MD5.hexdigest(File.open(file, 'rb'){ |fs| fs.read })
    is_update = args[:is_update].present? && args[:file_id].present?

    start_result = start_upload(
      folder_id:,
      file_name:,
      file_size: file.size,
      content_type:,
      file_mode: is_update ? 'UPDATE' : 'UPLOAD',
      file_id: args.fetch(:file_id, 0),
      md5:,
      file_path: args.fetch(:file_path, ''),
      file_code: args.fetch(:file_code, ''),
      remark: args.fetch(:remark, '')
    )

    max_block_length = 1024 * 1024 * 5

    file_result = {
      upload_id: start_result[:upload_id],
      file_name: start_result[:file_name],
      file_id: start_result[:file_id],
      file_ver_id: start_result[:file_ver_id],
      folder_id: start_result[:folder_id],
    }

    return file_result if start_result[:second_pass]

    # 上传文件块
    chunk = 0
    chunks = (file.size.to_f / max_block_length).ceil

    Rails.logger.tagged(start_result[:upload_id]) { |logger| logger.info "第二步 - 上传文件块" }
    Rails.logger.tagged(start_result[:upload_id]) { |logger| logger.info "文件大小: #{file.size}" }
    Rails.logger.tagged(start_result[:upload_id]) { |logger| logger.info "分片: #{chunks}" }

    File.open(file, 'r') do |f|
      until f.eof?
        stream = f.read(max_block_length)
        block_size = stream.size
        tempfile = Tempfile.create
        tempfile.binmode
        tempfile.syswrite(stream)

        chunk_result = chunk_upload(
          tempfile,
          upload_id: start_result[:upload_id],
          region_hash: start_result[:region_hash],
          region_id: start_result[:region_id],
          region_type: start_result[:region_type],
          region_url: start_result[:region_url],
          file_name: start_result[:file_name],
          file_size: start_result[:file_size],
          md5: start_result[:md5],
          chunks:,
          chunk:,
          chunk_size: max_block_length,
          block_size:
        )

        return file_result if chunk_result[:second_pass]

        chunk += 1
      end
    end

    file_result
  end

  # 查看文件信息
  # @param file_id [Integer] - 文件ID
  # @return [Hash]
  def self.info(file_id)
    path = '/api/services/File/GetFileInfoById'
    params = Edoc::Helpers.hash_with_token(fileId: file_id)

    url = Edoc::Helpers.url(path, params)

    result = Edoc::Helpers.parse_response(HTTP.get(Edoc::Helpers.url(path, params)))

    raise StandardError.new(result) unless result[:result] == 0

    {
      file_id: result[:data][:FileId], # integer 文件id
      file_name: result[:data][:FileName], # string 文件名称
      file_size: result[:data][:FileSize], # integer 文件大小
      code: result[:data][:Code], # string 文件编号
      file_modify_time: result[:data][:FileModifyTime], # string 文件修改时间
      editor_name: result[:data][:EditorName], # string 文件修改人姓名
      file_create_time: result[:data][:FileCreateTime], # string 文件创建时间
      creator_id: result[:data][:CreatorId], # integer 创建人id
      creator_name: result[:data][:CreatorName], # string 创建人姓名
      file_create_operator_name: result[:data][:FileCreateOperatorName], # string 创建人姓名
      current_operator: result[:data][:CurrentOperator], # string 当前操作人
      current_operator_id: result[:data][:CurrentOperatorId], # integer 当前操作人id
      current_version_id: result[:data][:CurrentVersionId], # integer 当前文件版本id
      last_version_id: result[:data][:LastVersionId], # integer 最新文件版本id
      file_cur_ver_num_str: result[:data][:FileCurVerNumStr], # string 文件当前版本id字符串
      file_last_ver_num_str: result[:data][:FileLastVerNumStr], # string 文件最新版本id字符串
      file_state: result[:data][:FileState], # integer 文件状态
      file_remark: result[:data][:FileRemark], # string 文件备注
      parent_folder_id: result[:data][:ParentFolderId], # integer 父级文件夹id
      file_path: result[:data][:FilePath], # string 文件路径
      file_name_path: result[:data][:FileNamePath], # string 文件名称路径
      inc_id: result[:data][:IncId], # string 其流程中的实例ID（当文件是在走流程中，则有值，否则为空）
      file_archive_time: result[:data][:FileArchiveTime], # string 文件归档时间
      permission: result[:data][:Permission], # integer 权限值
      file_type: result[:data][:FileType], # integer 文件类型
      is_deleted: result[:data][:IsDeleted], # boolean 是否已删除
      security_level_id: result[:data][:SecurityLevelId], # integer 密级id
      sec_level_name: result[:data][:SecLevelName], # string 密级名称
      sec_level_degree: result[:data][:SecLevelDegree], # integer 密级程度
      effective_time: result[:data][:EffectiveTime], # string 生效时间
      expiration_time: result[:data][:ExpirationTime], # string 过期时间
      is_favorite: result[:data][:IsFavorite], # boolean 是否被收藏
      file_cipher_text: result[:data][:FileCipherText], # boolean 是否为密文字段
      is_code_rules: result[:data][:IsCodeRules], # boolean 是否存在规则
      file_ext_name: result[:data][:FileExtName], # string 文件扩展名
      relate_mode: result[:data][:RelateMode], # integer 关联方式
      can_preview: result[:data][:CanPreview], # boolean 能否预览
      can_download: result[:data][:CanDownload], # boolean 能否下载
      can_delete_file: result[:data][:CanDeleteFile], # boolean 能否删除
      attach_type: result[:data][:AttachType], # integer 附件类型
      file_last_ver_ext_name: result[:data][:FileLastVerExtName], # string 文件最新版本扩展名
    }
  end

  # 文件外发
  # @param file_ids [Array<Integer>] - 文件ID列表
  # @param name: [String] - 外发名称
  # @param end_time: [String] - 过期时间，格式YYYY-MM-DD
  # @param auth_type: [Integer] - 验证类型:1:无密码;2:有密码
  # @param pwd: [String] - 外发密码
  # @param can_edit: [Boolean] - 是否可编辑:true或者false
  # @param can_download: [Boolean] - 是否可下载：true或者false
  # @param can_set_download_time: [Boolean] - 是否限制下载次数：true或者false
  # @param download_time: [Integer] - 下载次数:canSetDownloadTime为false：默认-1
  # @param can_preview_time: [Boolean] - 是否启用预览次数控制:true或false
  # @param preview_times: [Integer] - 预览次数:默认0
  # @param remark: [String] - 备注
  # @return [String] - 外发code
  def self.publish(
    file_ids,
    name:,
    end_time:,
    auth_type: 1,
    pwd: '',
    can_edit: false,
    can_download: false,
    can_set_download_time: false,
    download_time: -1,
    can_preview_time: false,
    preview_times: 0,
    remark: ''
  )
    path = '/api/services/DocPublish/CreateFilePublish'
    params = Edoc::Helpers.hash_with_token({
      fileIds: file_ids.join(','),
      publishEndTime: end_time,
      publishName: name,
      authType: auth_type,
      canDownload: can_download,
      canEdit: can_edit,
      canSetDownloadTime: can_set_download_time,
      downloadTime: download_time,
      pwdStr: pwd,
      outpublishRemark: remark,
      canpreviewTime: can_preview_time,
      previewTimes: preview_times,
    })

    url = Edoc::Helpers.url(path, params)
    result = Edoc::Helpers.parse_response(HTTP.get(Edoc::Helpers.url(path, params)))

    raise StandardError.new(result) unless result[:Result] == 0

    result[:Data]
  end
end
