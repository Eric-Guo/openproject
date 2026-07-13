# frozen_string_literal: true

module OpenProject::TextFormatting::Filters::Macros
  module ShowDdsFileLink
    class << self
      include OpenProject::StaticRouting::UrlHelpers
    end

    HTML_CLASS = "show_dds_file_link"

    module_function

    def identifier
      HTML_CLASS
    end

    def apply(macro, **)
      macro.replace render_dds_file_link(macro)
    end

    def render_dds_file_link(macro)
      file_info = macro["data-file"] || "null"
      class_name = macro["class"] || ""

      file = JSON.parse(file_info)

      if file["type"] == "publish_files"
        create_outer_share_link(file, class_name)
      else
        create_inner_share_link(file, class_name)
      end
    end

    def create_inner_share_link(file, class_name)
      helpers.tag.div(class: class_name) do
        helpers.safe_join([dds_file_link(file), dds_description(file["parentFolderFullPath"])].compact)
      end
    end

    def create_outer_share_link(file, class_name)
      helpers.tag.div(class: class_name) do
        links = file.fetch("files").map { |shared_file| dds_file_link(shared_file) }
        helpers.safe_join(links << outer_share_description(file))
      end
    end

    def dds_file_link(file)
      helpers.tag.p(class: "dds-file") do
        helpers.link_to(
          file["name"],
          file["url"],
          class: "dds-link",
          target: "_blank",
          rel: "noreferrer",
          data: { is_folder: !!file["isFolder"] }
        )
      end
    end

    def dds_description(description)
      helpers.tag.p(description, class: "dds-description") if description.present?
    end

    def outer_share_description(file)
      link = helpers.link_to(file["url"], file["url"], class: "dds-link", target: "_blank", rel: "noreferrer")
      details = "，验证码：【#{file['pwd'].presence || '无'}】，有效期：#{file['expiredAt']}"

      helpers.tag.p(class: "dds-description") do
        helpers.safe_join(["外链分享地址：", link, details])
      end
    end

    def helpers
      ApplicationController.helpers
    end
  end
end
