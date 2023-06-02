module API
  module V3
    module ProjectProfiles
      class ProjectProfileRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::Decorators::DateProperty
        include ::API::Caching::CachedRepresenter
        include API::Decorators::FormattableProperty

        self_link

        property :id

        property :code

        property :name

        property :type_id

        property :project_id,
                  uncacheable: true,
                  getter: ->(*) {
                    next unless project.present?
                    project.id
                  }

        property :project_name,
                  uncacheable: true,
                  getter: ->(*) {
                    next unless project.present?
                    project.name
                  }

        def _type
          'ProjectProfile'
        end

        self.to_eager_load = [:project]

        self.checked_permissions = [:add_work_packages]
      end
    end
  end
end
