require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackageEdocFiles
      class WorkPackageEdocFileRepresenter < ::API::Decorators::Single
        include API::Decorators::DateProperty
        include API::Caching::CachedRepresenter

        self_link id_attribute: ->(*) { represented.file_id },
                  title_getter: ->(*) { represented.file_name }

        property :folder_id, render_nil: true

        property :file_id, render_nil: true

        property :file_name, render_nil: true

        property :upload_id, render_nil: true

        property :md5, render_nil: true

        property :file_size, render_nil: true

        property :file_ver_id, render_nil: true

        property :region_hash, render_nil: true

        property :region_id, render_nil: true

        property :region_type, render_nil: true

        property :region_url, render_nil: true

        property :chunks, render_nil: true

        property :chunk_size, render_nil: true

        property :status, render_nil: true

        property :content_type, render_nil: true

        property :publish_preview_url, render_nil: true

        property :preview_url, render_nil: true

        date_time_property :created_at, render_nil: true

        date_time_property :updated_at, render_nil: true

        links :folder,
              uncacheable: true do
          {
            href: api_v3_paths.work_package_edoc_folder(represented.folder_id)
          }
        end

        links :upload,
              if: ->(*) { represented.status == 0 },
              uncacheable: true do
          {
            method: :post,
            href: api_v3_paths.upload_work_package_edoc_file(represented.file_id)
          }
        end

        links :user,
              uncacheable: true do
          next if represented.user.nil?
          {
            href: api_v3_paths.user(represented.user.id),
            title: represented.user.name
          }
        end

        links :remove,
              uncacheable: true do
          {
            method: :delete,
            href: api_v3_paths.work_package_edoc_file(represented.file_id)
          }
        end

        def _type
          'WorkPackageEdocFile'
        end
      end
    end
  end
end
