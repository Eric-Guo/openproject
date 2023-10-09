class Edoc::Folders
  # 判断文件夹是否存在
  # @param folder_id [Integer] - 文件夹ID
  # @return [Boolean]
  def self.existed?(folder_id)
    path = '/api/services/Folder/IsExistfolderByfolderId'
    params = Edoc::Helpers.hash_with_token(folderId: folder_id)

    url = Edoc::Helpers.url(path, params)
    result = Edoc::Helpers.parse_response(HTTP.get(url))

    raise StandardError.new(result) unless result[:result] == 0

    result[:data]
  end

  # 判断文件夹名称是否存在于某个文件夹中
  # @param folder_name [String] - 文件夹名称
  # @param folder_id [Integer] - 文件夹ID
  # @return [Boolean]
  def self.name_in_folder?(folder_name, folder_id)
    path = '/api/services/Folder/IsExistfolderInFolderByfolderName'
    params = Edoc::Helpers.hash_with_token(folderId: folder_id, folderName: folder_name)

    url = Edoc::Helpers.url(path, params)
    result = Edoc::Helpers.parse_response(HTTP.get(url))

    raise StandardError.new(result) unless result[:result] == 0

    result[:data]
  end

  # 在文件夹中通过文件夹名称查找文件夹ID
  # @param folder_name [String] - 文件名称
  # @param folder_id [Integer] - 文件夹ID
  # @return [Integer] - 文件夹ID，未找到返回nil
  def self.id_by_name(folder_name, folder_id)
    path = '/api/services/Folder/GetFolderIdInFolderByfolderName'
    params = Edoc::Helpers.hash_with_token(folderId: folder_id, folderName: folder_name)

    url = Edoc::Helpers.url(path, params)
    result = Edoc::Helpers.parse_response(HTTP.get(url))

    raise StandardError.new(result) unless result[:result] == 0

    return nil unless result[:data] > 0

    result[:data]
  end

  # 获取子文件夹列表
  # @param folder_id [Integer] - 文件夹ID
  # @return [Array<Hash{folder_id=>Integer folder_name=>String}>]
  def self.list(folder_id)
    path = '/api/services/Folder/GetChildrenFolders'
    params = Edoc::Helpers.hash_with_token(topFolderId: folder_id)

    url = Edoc::Helpers.url(path, params)
    result = Edoc::Helpers.parse_response(HTTP.get(url))

    raise StandardError.new(result) unless result[:result] == 0

    result[:data].map do |item|
      {
        folder_id: item[:FolderId],
        folder_name: item[:FolderName],
      }
    end
  end

  # 创建文件夹
  # @param parent_folder_id: [String] - 父文件夹
  # @param name: [String] - 文件夹名称
  # @param folder_code: [String] - 文件夹编号
  # @param remark: [String] - 备注
  # @return [Hash{folder_id=>Integer folder_name=>String}]
  def self.create(parent_folder_id:, name:, **args)
    path = '/api/services/Folder/CreateFolder'
    headers = { 'Content-Type': 'application/json' }
    json = Edoc::Helpers.hash_with_token({
      ParentFolderId: parent_folder_id,
      Name: name,
      FolderCode: args.fetch(:folder_code, ''),
      Remark: args.fetch(:remark , ''),
    }, :Token)

    response = HTTP.headers(headers).post(Edoc::Helpers.url(path), json:)
    result = Edoc::Helpers.parse_response(response)

    raise StandardError.new(result) unless result[:result] == 0 || result[:result] == 806

    {
      folder_id: result[:data][:FolderId],
      folder_name: result[:data][:Name],
    }
  end

  # 删除文件夹
  # @param folder_ids [Array<Integer>] - 文件ID列表
  # @return [nil]
  def self.remove(*folder_ids)
    path = '/api/services/Doc/RemoveFolderListAndFileList'
    headers = { 'Content-Type': 'application/json' }
    data = Edoc::Helpers.hash_with_token(FolderIdList: folder_ids)

    response = HTTP.headers(headers).post(Edoc::Helpers.url(path), json: data)
    result = Edoc::Helpers.parse_response(response)

    raise StandardError.new(result) unless result[:result] == 0

    result[:data]
  end

  # 根据文件夹id获取文件夹信息
  # @param folder_id [Integer] - 文件夹ID
  # @return [Hash]
  def self.info(folder_id)
    path = '/api/services/Folder/GetFolderInfoById'
    params = Edoc::Helpers.hash_with_token({
      folderId: folder_id,
    })

    result = Edoc::Helpers.parse_response(HTTP.get(Edoc::Helpers.url(path, params)))

    raise StandardError.new(result) unless result[:result] == 0

    {
      child_file_count: result[:data][:ChildFileCount], # 子文件数量
      child_folder_count: result[:data][:ChildFolderCount], # 子文件夹数量
      code: result[:data][:Code], # 编号
      create_time: result[:data][:CreateTime], # 创建时间
      creator_id: result[:data][:CreatorId], # 创建人id
      creator_name: result[:data][:CreatorName], # 创建人名称
      editor_id: result[:data][:EditorId], # 修改人id
      editor_name: result[:data][:EditorName], # 修改人名称
      favorite_id: result[:data][:FavoriteId], # 收藏id
      favorite_type: result[:data][:FavoriteType], # 收藏类型
      folder_type: result[:data][:FolderType], # 文件夹类型
      folder_id: result[:data][:FolderId], # 文件夹id
      is_sec_folder: result[:data][:IsSecFolder], # 是否启用内容安全引擎
      isfavorite: result[:data][:Isfavorite], # 是否已收藏
      max_folder_size: result[:data][:MaxFolderSize], # 最大文件夹大小
      modify_time: result[:data][:ModifyTime], # 修改时间
      folder_name: result[:data][:FolderName], # 文件夹名称
      parent_folder_id: result[:data][:ParentFolderId], # 父级文件夹id
      folder_path: result[:data][:FolderPath], # 文件夹路径
      permission: result[:data][:Permission], # 权限值
      remark: result[:data][:Remark], # 备注
      security_level_name: result[:data][:SecurityLevelName], # 密级名称
      sec_level_degree: result[:data][:SecLevelDegree], # 密级度
      security_level_id: result[:data][:SecurityLevelId], # 密级id
      folder_state: result[:data][:FolderState], # 文件夹状态
      folder_size: result[:data][:FolderSize], # 文件夹大小
      upload_type: result[:data][:UploadType], # 上传方式
      is_deleted: result[:data][:IsDeleted], # 是否已删除
    }
  end

  # 文件夹外发
  # @param file_ids [Array<Integer>] - 文件ID列表
  # @param name: [String] - 外发名称
  # @param end_time: [String] - 过期时间，格式YYYY-MM-DD
  # @param auth_type: [Integer] - 验证类型:1:无密码;2:有密码
  # @param pwd: [String] - 外发密码
  # @param can_edit: [Boolean] - 是否可编辑:true或者false
  # @param can_upload: [Boolean] - 是否可上传:true或者false
  # @param can_download: [Boolean] - 是否可下载：true或者false
  # @param can_set_download_time: [Boolean] - 是否限制下载次数：true或者false
  # @param download_time: [Integer] - 下载次数:canSetDownloadTime为false：默认-1
  # @param remark: [String] - 备注
  # @return [String] - 外发code
  def self.publish(
    folder_ids,
    name:,
    end_time:,
    auth_type: 1,
    pwd: '',
    can_edit: false,
    can_upload: false,
    can_download: false,
    can_set_download_time: false,
    download_time: -1,
    remark: ''
  )
    path = '/api/services/DocPublish/CreateFolderPublish'
    params = Edoc::Helpers.hash_with_token({
      folderIdList: folder_ids.join(','),
      endTime: end_time,
      outpublishName: name,
      outpublishAuthType: auth_type,
      outpublishPwd: pwd,
      canDownload: can_download,
      canEdit: can_edit,
      canUpload: can_edit,
      canSetDownloadTime: can_set_download_time,
      downloadTime: download_time,
      outpublishRemark: remark,
    })

    url = Edoc::Helpers.url(path, params)

    result = Edoc::Helpers.parse_response(HTTP.get(Edoc::Helpers.url(path, params)))

    raise StandardError.new(result) unless result[:Result] == 0

    result[:Message]
  end
end
