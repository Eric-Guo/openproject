module API
  module V3
    module ThQueries
      module Helpers
        module QueryRepresenterResponse
          def get_wps(query, ids, user)
            return [] if ids.blank?

            ::API::V3::WorkPackages::WorkPackageEagerLoadingWrapper.wrap(
              ids,
              user,
              query:
            )
          end

          def get_wps_ancestors(query, wps, user)
            return [] if wps.blank?

            ids = wps.map(&:id)

            ancestor_ids = WorkPackageHierarchy.where(descendant_id: ids).order(generations: :asc).pluck(:ancestor_id).uniq

            ancestor_ids = ancestor_ids - ids

            get_wps(query, ancestor_ids, user)
          end

          def query_response_call(query, params, user, valid_subset = false)
            call = ::API::V3::WorkPackageCollectionFromQueryService
                    .new(query, user)
                    .call(params, valid_subset:)

            return call unless call.success?

            elements = call.result.represented

            ancestors = get_wps_ancestors(query, elements, user)

            call.result.instance_variable_set(:@represented, elements + ancestors)

            call
          end

          def query_representer_response(query, params, valid_subset = false)
            call = raise_invalid_query_on_service_failure do
              query_response_call(query, params, current_user, valid_subset)
            end

            ::API::V3::Queries::QueryRepresenter.new(
              query,
              current_user:,
              results: call.result,
              embed_links: true,
              params:
            )
          end
        end
      end
    end
  end
end
