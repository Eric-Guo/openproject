module OpenProject::TextFormatting::Filters::Macros
  module ShowDdsFileLink
    class << self
      include OpenProject::StaticRouting::UrlHelpers
    end

    HTML_CLASS = 'show_dds_file_link'.freeze

    module_function

    def identifier
      HTML_CLASS
    end

    def apply(macro, result:, context:)
      macro.replace dds_file_link(macro, context)
    end

    def dds_file_link(macro, context)
      file_info = macro['data-file'] || 'null'
      class_name = macro['class'] || ''

      file_obj = OpenStruct.new(JSON.parse(file_info))

      ApplicationController.helpers.tag.div(
        class: class_name,
        data: {
          is_folder: !!file_obj.isFolder
        }
      ) do
        p1 = ApplicationController.helpers.tag.p do
          ApplicationController.helpers.link_to(
            file_obj.name,
            file_obj.url,
            target: '_blank',
            rel: 'noreferrer',
            data: {
              is_folder: !!file_obj.isFolder
            }
          )
        end

        p2 = if file_obj.parentFolderFullPath.present?
          ApplicationController.helpers.tag.p do
            file_obj.parentFolderFullPath
          end
        else
          ''
        end

        p1 + p2
      end
    end
  end
end
