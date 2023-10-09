# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::ThWorkPackages
  class Engine < ::Rails::Engine
    engine_name :openproject_th_work_packages

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-th_work_packages',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 6.0.0'

    patches %i[WorkPackage]
  end
end
