require 'securerandom'
require 'api/v3/queries/query_representer'

module API
  module V3
    module ThQueries
      class ThQueriesAPI < ::API::OpenProjectAPI
        resources :th_queries do
          helpers ::API::V3::ThQueries::Helpers::QueryRepresenterResponse

          helpers do
            def authorize_by_policy(action, &block)
              authorize_by_with_raise(-> { allowed_to?(action) }, &block)
            end

            def allowed_to?(action)
              QueryPolicy.new(current_user).allowed?(@query, action)
            end
          end

          route_param :id, type: Integer, desc: 'Query ID' do
            after_validation do
              @query = Query.find(params[:id])
            end

            params do
              optional :valid_subset, type: Boolean
            end

            get do
              # We try to ignore invalid aspects of the query as the user
              # might not even be able to fix them (public  query)
              # and because they might only be invalid in his context
              # but not for somebody having more permissions, e.g. subproject
              # filter for admin vs for anonymous.
              # Permissions are enforced nevertheless.
              @query.valid_subset!

              # We do not ignore invalid params provided by the client
              # unless explicitly required by valid_subset
              query_representer_response(@query, params, params.delete(:valid_subset))
            end
          end
        end
      end
    end
  end
end
