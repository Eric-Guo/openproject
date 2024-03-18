Debugbar.configure do |config|
  config.enabled = ENV["ENABLE_DEBUGBAR"] == "true"
end if Rails.env.development?
