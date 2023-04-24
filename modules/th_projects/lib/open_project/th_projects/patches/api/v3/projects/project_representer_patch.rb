module OpenProject::ThProjects
  module Patches::API::V3::Projects::ProjectRepresenterPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do

        link :profile do
          next unless represented.profile.present?
          {
            href: api_v3_paths.project_profile(represented.profile.id),
            name: represented.profile.name,
            code: represented.profile.code,
            docLink: represented.profile.doc_link,
            typeId: represented.profile.type_id,
          }
        end

      end
    end

    module InstanceMethods
    end
  end
end
