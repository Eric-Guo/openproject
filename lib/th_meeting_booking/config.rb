class ThMeetingBooking::Config
  # 获取环境变量
  # @param key [String]
  # @return [String]
  def self.env(key)
    ENV["TH_MEETING_BOOKING_#{key.upcase}"]
  end

  # 域名
  # @return [String]
  def self.host
    env('HOST')
  end

  # 路径前缀
  # @return [String]
  def self.path_prefix
    env('PATH_PREFIX')
  end

  # x-app-id
  # @return [String]
  def self.app_id
    env('APP_ID')
  end

  # x-app-secret
  # @return [String]
  def self.app_secret
    env('APP_SECRET')
  end
end
