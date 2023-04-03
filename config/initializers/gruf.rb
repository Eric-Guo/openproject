require 'gruf'

proto_dir = File.join(Rails.root, 'lib', 'proto')
$LOAD_PATH.unshift(proto_dir)
require 'app/proto/open_project_services_pb'

Gruf.configure do |c|
  c.interceptors.use(::Gruf::Interceptors::Instrumentation::RequestLogging::Interceptor, formatter: :logstash)
  c.error_serializer = Gruf::Serializers::Errors::Json

  c.default_client_host = ENV['GRUF_OP_SERVER']
end

OpenProject::Application.configure do
  config.after_initialize do
    Spring.after_fork do
      $gruf_op_client = ::Gruf::Client.new(service: OpService)
    end
  end
end
