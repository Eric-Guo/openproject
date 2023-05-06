module OpenProject::ThProjects
  module Patches::Projects::BaseContractPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        attribute :profile
      end
    end

    module InstanceMethods
    end
  end
end
