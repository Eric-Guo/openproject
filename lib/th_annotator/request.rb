class ThAnnotator::Request
  def self.create
    request = new
    yield request if block_given?
    request
  end

  def self.http
    headers = {}
    if Rails.env.development?
      HTTP.use(logging: { logger: Rails.logger }).headers(headers)
    else
      HTTP.headers(headers)
    end
  end

  %i[get post put patch delete].each do |method|
    define_method(method) do |path, params: nil, fragment: nil, headers: nil, data: nil|
      current_http = http

      url = ThAnnotator::Helpers.url(
        ThAnnotator::Helpers.request_path(path),
        params,
        fragment
      )

      current_http = current_http.headers(headers) if headers.present?

      response = current_http.send(method, url, json: data)

      raise StandardError.new("访问天华批注服务器失败, #{response.status}") unless response.status.success?

      result = JSON.parse(response.body.to_s).with_indifferent_access

      unless result[:code] == 0
        raise StandardError.new(result[:msg])
      end

      result
    end
  end

  private

  def http
    @http ||= self.class.http
  end
end
