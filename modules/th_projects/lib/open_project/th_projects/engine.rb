# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::ThProjects
  class Engine < ::Rails::Engine
    engine_name :openproject_th_projects

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-th_projects',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 6.0.0',
             :name => :project_module_th_projects do
      project_module :th_projects do
        permission :view_th_projects,
                    {
                      'th_projects/project_profiles': %i[update]
                    },
                    require: :project
      end
    end

    patches %i[Project API::V3::Projects::ProjectRepresenter]

    add_api_path :project_profile do |id|
      "#{project(id)}/profile"
    end

    add_api_endpoint 'API::V3::Projects::ProjectsAPI', :id do
      mount ::API::V3::Projects::Profiles::ProfilesAPI
    end
  end
end
