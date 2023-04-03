# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::ThNotifications
  class Engine < ::Rails::Engine
    engine_name :openproject_th_notifications

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-th_notifications',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 6.0.0',
             :name => :project_module_th_notifications

    patches %i[Notification]
  end
end
