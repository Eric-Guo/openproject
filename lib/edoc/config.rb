class Edoc::Config
  # 天华云Host
  # @return [String]
  def self.host
    ENV['EDOC_HOST']
  end

  # 天华云Token
  # @return [String]
  def self.token
    ENV['EDOC_TOKEN']
  end

  # 工作包文件夹ID
  # @return [String]
  def self.wp_folder
    ENV['EDOC_WP_FOLDER']
  end
end
