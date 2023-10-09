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
    return '' unless hash.present?
    hash.to_a.reduce('') do |query, item|
      key, value = item
      query << "&#{key.to_s}=#{URI.encode_www_form_component(value)}" unless value.nil?
      query
    end.sub(/^&/, '')
  end

  # 生成URL
  def self._url(host, path, params = {})
    url = URI(Pathname.new(host).join(path.sub(/^\/+/, '')).to_s)

    hash = query2hash(url.query)

    hash.merge!(params)

    url.query = hash2query(hash)

    url.to_s
  end

  # 获取请求url
  # @param path [String] - 路径
  # @param params [Hash] - 参数
  # @return [String]
  def self.url(path, params = {})
    _url(Edoc::Config.host, path, params)
  end

  # 解析响应值
  def self.parse_response(response)
    if Rails.env.development?
      Rails.logger.tagged('Edoc::Helpers.parse_response') do |logger|
        logger.tagged('reponse') { |logger| logger.info response.inspect }
        logger.tagged('reponse body') { |logger| logger.info response.body.to_s }
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
end
