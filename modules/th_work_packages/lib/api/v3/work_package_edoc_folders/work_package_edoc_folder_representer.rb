require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackageEdocFolders
      class WorkPackageEdocFolderRepresenter < ::API::Decorators::Single
        self_link id_attribute: ->(*) { represented.folder_id },
                  title_getter: ->(*) { represented.folder_name }

        include API::Caching::CachedRepresenter

        property :folder_id, render_nil: true

        property :folder_name, render_nil: true

        property :publish_code, render_nil: true

        property :publish_url, render_nil: true

        links :files,
              uncacheable: true do
          {
            href: api_v3_paths.edoc_files_by_work_package_edoc_folder(represented.folder_id)
          }
        end

        links :create_file,
              uncacheable: true do
          {
            method: :post,
            href: api_v3_paths.create_edoc_file_by_work_package_edoc_folder(represented.folder_id)
          }
        end

        def _type
          'WorkPackageEdocFolder'
        end
      end
    end
  end
end
