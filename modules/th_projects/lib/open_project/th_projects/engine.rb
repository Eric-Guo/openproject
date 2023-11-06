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
        permission :view_th_project_profiles,
                    {
                      'th_projects/project_profiles': %i[update],
                    },
                    require: :project

        permission :view_th_project_timelines,
                    {
                      'th_projects/project_timelines': %i[show],
                    },
                    require: :project

        permission :view_th_project_more,
                    {
                      'th_projects/project_more': %i[show],
                    },
                    require: :project
      end

      menu :project_menu,
        :project_timeline,
        { controller: '/th_projects/project_timelines', action: 'show' },
        if: ->(project) { project.module_enabled?(:th_projects) && User.current.logged? && User.current.allowed_to?(:view_th_project_timelines, project) },
        caption: :label_project_timeline_plural,
        icon: 'icon2 icon-time',
        before: :settings

      menu :project_menu,
        :project_more,
        { controller: '/th_projects/project_more', action: 'show' },
        if: ->(project) { project.module_enabled?(:th_projects) && User.current.logged? && User.current.allowed_to?(:view_th_project_more, project) },
        caption: :label_project_more_plural,
        icon: 'icon2 icon-more',
        before: :settings
    end

    patches %i[Project Projects::BaseContract API::V3::Projects::Schemas::ProjectSchemaRepresenter]

    add_api_path :project_profiles do
      "#{root}/project_profiles"
    end

    add_api_path :project_profile do |id|
      "#{root}/project_profiles/#{id}"
    end

    add_api_endpoint 'API::V3::Root' do
      mount ::API::V3::ProjectProfiles::ProjectProfilesAPI
    end
  end
end
