# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::ThQueries
  class Engine < ::Rails::Engine
    engine_name :openproject_th_queries

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-th_queries',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 6.0.0'

    add_api_path :th_query do |id|
      "#{root}/th_queries/#{id}"
    end

    add_api_endpoint 'API::V3::Root' do
      mount ::API::V3::ThQueries::ThQueriesAPI
    end

    add_api_endpoint 'API::V3::Projects::ProjectsAPI', :id do
      mount ::API::V3::ThQueries::ThQueriesByProjectAPI
    end
  end
end
