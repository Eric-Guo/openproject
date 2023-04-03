require 'gruf'

Gruf.configure do |c|
  c.interceptors.use(::Gruf::Interceptors::Instrumentation::RequestLogging::Interceptor, formatter: :logstash)
  c.error_serializer = Gruf::Serializers::Errors::Json

  c.default_client_host = ENV['GRUF_OP_SERVER']
end

OpenProject::Application.configure do
  config.after_initialize do
    if Rails.env.development?
      Spring.after_fork do
        $gruf_op_client = ::Gruf::Client.new(service: Proto::OpService)
      end
    end
    if Rails.env.production?
      $gruf_op_client = ::Gruf::Client.new(service: Proto::OpService)
    end
  end
end
