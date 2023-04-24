module OpenProject::ThProjects
  module Patches::ProjectPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_one :profile, class_name: "ProjectProfile", foreign_key: "project_id"
      end
    end

    module InstanceMethods
    end
  end
end
