# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::ThMeetings
  class Engine < ::Rails::Engine
    engine_name :openproject_th_meetings

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-th_meetings',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 6.0.0'

    patches %i[Meeting MeetingsController]
  end
end
