module ThWorkPackages
  class TemplatesController < ::ApplicationController
    def index
      @templates = Edoc::Files.list(ENV['EDOC_WP_TEMPLATE_FOLDER'])

      render json: @templates
    end

    def download
      edoc_file = Edoc::Files.info(params[:id])

      result = Edoc::Files.download(edoc_file[:file_id])

      send_data result.body, filename: edoc_file[:file_name]
    end
  end
end
