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

      if file_obj.type == 'publish_files'
        create_outer_share_link(file_obj, class_name)
      else
        create_inner_share_link(file_obj, class_name)
      end
    end

    def create_inner_share_link(file_obj, class_name)
      ApplicationController.helpers.tag.div(class: class_name) do
        content = ''
        content << ApplicationController.helpers.tag.p(class: 'dds-file') do
          ApplicationController.helpers.link_to(
            file_obj.name,
            file_obj.url,
            class: 'dds-link',
            target: '_blank',
            rel: 'noreferrer',
            data: {
              is_folder: !!file_obj.isFolder
            }
          )
        end

        if file_obj.parentFolderFullPath.present?
          content << ApplicationController.helpers.tag.p(class: 'dds-description') do
            file_obj.parentFolderFullPath
          end
        end

        content.html_safe
      end
    end

    def create_outer_share_link(file_obj, class_name)
      ApplicationController.helpers.tag.div(class: class_name) do
        content = ''
        file_obj.files.each do |file|
          file = OpenStruct.new(file)
          content << ApplicationController.helpers.tag.p(class: 'dds-file') do
            ApplicationController.helpers.link_to(
              file.name,
              file.url,
              class: 'dds-link',
              target: '_blank',
              rel: 'noreferrer',
              data: {
                is_folder: !!file.isFolder
              }
            )
          end
        end

        content << ApplicationController.helpers.tag.p(class: 'dds-description') do
          text = '外链分享地址：'
          text << ApplicationController.helpers.link_to(
            file_obj.url,
            file_obj.url,
            class: 'dds-link',
            target: '_blank',
            rel: 'noreferrer',
          )
          text << "，验证码：【#{file_obj.pwd.presence || '无'}】，有效期：#{file_obj.expiredAt}"

          text.html_safe
        end

        content.html_safe
      end
    end
  end
end
