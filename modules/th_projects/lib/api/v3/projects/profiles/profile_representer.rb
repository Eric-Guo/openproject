module API
  module V3
    module Projects
      module Profiles
        class ProfileRepresenter < ::API::Decorators::Single
          link :self do
            {
              href: api_v3_paths.project_profile(represented.project.id)
            }
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
