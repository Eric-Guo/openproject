module OpenProject::ThProjects
  module Patches::API::V3::Projects::ProjectRepresenterPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        resource :profile,
                 getter: ->(*) {
                   next unless represented.profile

                   ::API::V3::Projects::Profiles::ProfileRepresenter
                     .create(represented.profile, current_user:, embed_links:)
                 },
                 link: ->(*) {
                   if represented.profile
                     {
                       href: api_v3_paths.project_profile(represented.id),
                     }.compact
                   else
                     {
                       href: nil
                     }
                   end
                 },
                 setter: ->(fragment:, represented:, **) {
                 }
      end
    end

    module InstanceMethods
    end
  end
end
