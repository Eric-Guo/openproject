module OpenProject::ThProjects
  module Patches::API::V3::Projects::Schemas::ProjectSchemaRepresenterPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        schema :profile,
                type: 'ProjectProfile',
                required: false,
                show_if: ->(*) {
                  represented.model.module_enabled?('th_projects')
                }
      end
    end

    module InstanceMethods
    end
  end
end
