class ThAnnotator::Helpers
  # 生成请求路径
  # @param path [String] - 路径
  def self.request_path(path)
    Pathname(ThAnnotator::Config.path_prefix).join(path).to_s
  end

  # 将token添加到hash中
  # @return [Hash]
  def self.hash_with_token(hash = {}, k = :token)
    hash.merge(k.to_sym => ThAnnotator::Config.token)
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
  def self._url(host, path, query = nil, fragment = nil) # rubocop:disable Metrics/AbcSize
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
    _url(ThAnnotator::Config.host, path, params, fragment)
  end

  def self.jump_url(token:, uuid:)
    _url(ThAnnotator::Config.host, request_path('auth/authorize'), { token:, documentUUID: uuid })
  end
end
