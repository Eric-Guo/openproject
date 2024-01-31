class ThMeetingBooking::Request
  def self.create
    request = self.new
    yield request if block_given?
    request
  end

  def self.http
    headers = { :'x-app-id' => ThMeetingBooking::Config.app_id, :'x-app-secret' => ThMeetingBooking::Config.app_secret }
    if Rails.env.development?
      HTTP.use(logging: { logger: Rails.logger }).headers(headers)
    else
      HTTP.headers(headers)
    end
  end

  [:get, :post, :put, :patch, :delete].each do |method|
    define_method(method) do |path, params: nil, fragment: nil, headers: nil, data: nil|
      current_http = http

      url = ThMeetingBooking::Helpers.url(
        ThMeetingBooking::Helpers.request_path(path),
        params,
        fragment
      )

      current_http = current_http.headers(headers) if headers.present?

      response = current_http.send(method, url, json: data)

      raise StandardError.new("访问会议预定服务器失败, #{response.status.to_s}") unless response.status.success?

      result = JSON.parse(response.body.to_s).with_indifferent_access

      unless result[:code] == 0
        raise StandardError.new(result[:warnMessage]) if result[:data].blank? && result[:warnMessage].present?

        raise StandardError.new(result[:message])
      end

      result
    end
  end

  private

  def http
    @http ||= self.class.http
  end
end
