module API
  module V3
    module ThQueries
      class ThQueriesByProjectAPI < ::API::OpenProjectAPI
        namespace :th_queries do
          helpers ::API::V3::ThQueries::Helpers::QueryRepresenterResponse

          after_validation do
            authorize(:view_work_packages, context: @project, user: current_user)
          end

          namespace :default do
            get do
              query = Query.new_default(name: 'default',
                                        user: current_user,
                                        project: @project)

              query_representer_response(query, params)
            end
          end
        end
      end
    end
  end
end
