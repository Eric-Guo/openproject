module API
  module V3
    module ProjectProfiles
      class ProjectProfileRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::Decorators::DateProperty
        include ::API::Caching::CachedRepresenter
        include API::Decorators::FormattableProperty

        cached_representer key_parts: %i(project),
                           disabled: false

        self_link

        link :self do
          {
            href: api_v3_paths.project_profile(represented.id)
          }
        end

        link :project do
          if represented.project.present?
            {
              href: api_v3_paths.project(represented.project.id),
              title: represented.project.name,
            }
          end
        end

        property :id

        property :code

        property :name

        property :doc_link

        property :type_id

        property :project_id

        def _type
          'ProjectProfile'
        end

        self.to_eager_load = [:project]

        self.checked_permissions = [:add_work_packages]
      end
    end
  end
end
