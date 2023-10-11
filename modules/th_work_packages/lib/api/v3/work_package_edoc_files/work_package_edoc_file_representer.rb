require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackageEdocFiles
      class WorkPackageEdocFileRepresenter < ::API::Decorators::Single
        self_link id_attribute: ->(*) { represented.file_id },
                  title_getter: ->(*) { represented.file_name }

        include API::Caching::CachedRepresenter

        property :file_id, render_nil: true

        property :file_name, render_nil: true

        property :file_size, render_nil: true

        property :status, render_nil: true

        property :publish_preview_url, render_nil: true

        property :preview_url, render_nil: true

        links :folder,
              uncacheable: true do
          {
            href: api_v3_paths.work_package_edoc_folder(represented.folder_id)
          }
        end

        def _type
          'WorkPackageEdocFile'
        end
      end
    end
  end
end
