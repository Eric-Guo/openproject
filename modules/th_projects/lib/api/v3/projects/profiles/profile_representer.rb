module API
  module V3
    module Projects
      module Profiles
        class ProfileRepresenter < ::API::Decorators::Single
          link :self do
            if represented.project_id && represented.project_id != 0
              {
                href: api_v3_paths.project_profile(represented.project_id)
              }
            else
              {
                href: nil
              }
            end
          end

          property :id

          property :code

          property :name

          property :doc_link

          def _type
            'ProjectProfile'
          end
        end
      end
    end
  end
end
