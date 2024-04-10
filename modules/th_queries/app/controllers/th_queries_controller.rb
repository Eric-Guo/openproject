class ThQueriesController < ApplicationController
  def export_pdf
    user_id = current_user.id

    query_id = params[:query_id]

    project_id = params[:project_id]

    job = ExportWpsToThPdfJob.perform_later(user_id:, query_id:, project_id:)

    render json: job
  end
end
