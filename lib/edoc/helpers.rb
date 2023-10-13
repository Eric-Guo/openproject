class Edoc::Helpers
  # 将token添加到hash中
  # @return [Hash]
  def self.hash_with_token(hash = {}, k = :token)
    hash.merge(k.to_sym => Edoc::Config.token)
  end

  # URL query转hash
  # @param query [String] - URL?后面的内容
  # @return [Hash]
  def self.query2hash(query)
    return {} unless query.present? && query.is_a?(String)

    query.split('&').reduce({}) do |hash, item|
      key, value = item.split('=')
      hash[key.to_sym] = URI.decode_www_form_component(value) unless value.nil?
      hash
    end
  end

  # URL hash转query
  # @param hash [Hash]
  # @return [String]
  def self.hash2query(hash)
    return nil if hash.blank?

    hash.to_a.reduce('') do |query, item|
      key, value = item
      query << "&#{key}=#{URI.encode_www_form_component(value)}" unless value.nil?
      query
    end.sub(/^&/, '').presence
  end

  # 生成URL
  # @param host [String] - 主机，格式https://xxxx.com
  # @param path [String] - 路径
  # @param query [String|Hash] - url?xxxxxx
  # @param fragment [String|Hash] - url#xxxxxx
  # @return [String]
  def self._url(host, path, query = nil, fragment = nil)
    url = URI(Pathname.new(host).join(path.sub(/^\/+/, '')).to_s)

    if query.is_a?(Hash)
      hash = query2hash(url.query).merge!(query)
      url.query = hash2query(hash)
    end

    if query.is_a?(String)
      url.query = query
    end

    if fragment.is_a?(Hash)
      hash = query2hash(url.fragment).merge!(fragment)
      url.fragment = hash2query(hash)
    end

    if fragment.is_a?(String)
      url.fragment = fragment
    end

    url.to_s
  end

  # 获取请求url
  # @param path [String] - 路径
  # @param params [Hash] - 参数
  # @param fragment [String|Hash] - #部分
  # @return [String]
  def self.url(path, params = nil, fragment = nil)
    _url(Edoc::Config.host, path, params, fragment)
  end

  # 解析响应值
  def self.parse_response(response)
    if Rails.env.development?
      Rails.logger.tagged('Edoc::Helpers.parse_response') do |logger|
        logger.tagged('reponse') { |log| log.info response.inspect }
        logger.tagged('reponse body') { |log| log.info response.body.to_s }
      end
    end
    raise StandardError.new('访问天华云服务器失败') unless response.status.success?
    JSON.parse(response.body.to_s).with_indifferent_access
  end

  # 生成外发链接
  # @param code [String] - 外发code
  # @return [String]
  def self.publish_url(code)
    url('outpublish.html', { code: })
  end

  # 生成外发预览文件链接
  # @param code [String] - 外发code
  # @param file_id [Integer] - 文件ID
  # @return [String]
  def self.publish_preview_url(code, file_id)
    url('preview.html', { code:, fileid: file_id, ispublish: true })
  end

  # 生成预览文件链接
  # @param file_id [Integer] - 文件ID
  # @return [String]
  def self.preview_url(file_id)
    url('preview.html', { fileid: file_id })
  end

  # 生成文件夹链接
  # @param folder_id [Integer] - 文件夹ID
  # @return [String]
  def self.folder_url(folder_id, params = nil)
    url('/index.html', params, "doc/enterprise/#{folder_id}")
  end

  # 计算文件md5值
  # @param file [File] - 文件
  # @return [String]
  def self.calc_file_md5(file)
    md5 = Digest::MD5.new
    File.open(file, 'rb') do |f|
      while chunk = f.read(1024 * 1024 * 10) # 每次读取 10MB
        md5.update(chunk)
      end
    end
    md5.hexdigest
  end
end
