# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::ThMembers
  class Engine < ::Rails::Engine
    engine_name :openproject_th_members

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-th_members',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 6.0.0',
             :name => :project_module_th_members do
      project_module :th_members do
        permission :view_th_members,
                   {
                    'th_members/member_profiles': %i[update]
                   },
                   require: :member
      end
    end

    patches %i[Member API::V3::Memberships::MembershipRepresenter]

    add_api_path :membership_profile do |id|
      "#{membership(id)}/profile"
    end

    add_api_endpoint 'API::V3::Memberships::MembershipsAPI', :id do
      mount ::API::V3::Memberships::Profiles::ProfilesAPI
    end

    config.to_prepare do
      OpenProject::ThMembers::Patches::MembersPatch.mixin!
    end
  end
end
