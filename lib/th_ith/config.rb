class ThIth::Config
  # 获取环境变量
  # @param key [String]
  # @return [String]
  def self.env(key)
    ENV.fetch("TH_ITH_#{key.upcase}", nil)
  end

  # 域名
  # @return [String]
  def self.host
    env('HOST')
  end

  # 路径前缀
  # @return [String]
  def self.path_prefix
    env('PATH_PREFIX') || ''
  end
end
