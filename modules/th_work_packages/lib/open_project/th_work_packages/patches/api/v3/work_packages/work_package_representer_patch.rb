module OpenProject::ThWorkPackages
  module Patches::API::V3::WorkPackages::WorkPackageRepresenterPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        links :edoc_folder,
              uncacheable: true do
          {
            href: api_v3_paths.edoc_folder_by_work_package(represented.id)
          }
        end

        links :edoc_files,
              uncacheable: true do
          {
            href: api_v3_paths.edoc_files_by_work_package(represented.id)
          }
        end

        links :create_edoc_file,
              uncacheable: true do
          next unless represented.edoc_folder.present?
          {
            method: :post,
            href: api_v3_paths.create_edoc_file_by_work_package(represented.id)
          }
        end
      end
    end

    module InstanceMethods
    end
  end
end
