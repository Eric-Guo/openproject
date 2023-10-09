module OpenProject::ThWorkPackages
  module Patches::WorkPackagePatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_one :edoc_folder, class_name: "WorkPackageEdocFolder"

        has_many :edoc_files, through: :edoc_folder, source: :files

        after_create_commit :create_edoc_folder
      end
    end

    module InstanceMethods
      def create_edoc_folder
        ThWorkPackages::CreateEdocFolderJob.perform_later(id)
      end
    end
  end
end
