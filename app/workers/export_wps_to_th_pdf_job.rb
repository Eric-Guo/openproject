class ExportWpsToThPdfJob < ApplicationJob
  queue_with_priority :above_normal

  include ::API::V3::ThQueries::Helpers::QueryRepresenterResponse

  attr_reader :user_id,
              :query_id,
              :project_id

  def perform(user_id:, query_id: nil, project_id: nil)
    # Needs refactoring after moving to activejob

    @user_id    = user_id
    @query_id   = query_id
    @project_id = project_id

    @payload = {
      title:,
      user_id:,
      query_id:,
      project_id:
    }

    User.current = user

    send_by_grpc

    successful_status_update
  rescue StandardError => e
    logger.error { "视图数据生成天华 PDF 任务: #{e} #{e.message}" }
    @payload[:errors] = e.message
    failure_status_update
  end

  def store_status?
    true
  end

  def updates_own_status?
    true
  end

  protected

  def title
    '导出甘特图'
  end

  def payload
    @payload
  end

  private

  def successful_status_update
    upsert_status status: :success,
                  message: '工作包视图数据生成pdf成功',
                  payload:
  end

  def failure_status_update
    message = '工作包视图数据生成pdf失败'

    upsert_status status: :failure, message:, payload:
  end

  def default_query?
    query_id.nil? || query_id.to_s == 'default'
  end

  def user
    @user ||= User.find user_id
  end

  def query
    @query ||= begin
      if default_query?
        Query.new_default(
          name: 'default',
          user:,
          project:
        )
      else
        Query.find query_id
      end
    end
  end

  def project
    @project ||= Project.find project_id
  end

  def params
    { pageSize: 1000, offset: 1 }
  end

  def work_packages
    @work_packages ||= begin
      call = query_response_call(query, params, user)

      call.result.represented
    end
  end

  def work_package_remark(work_package)
    work_package.custom_values.detect { |custom_value| custom_value.custom_field.name == '备注' }&.value
  end

  def grpc_data
    @grpc_data ||= work_packages.map do |wp|
      {
        ID: wp.id,
        ReportProjectID: wp.project_id,
        Type: wp.type&.name,
        Subject: wp.subject,
        Status: wp.status&.name,
        StartTime: wp.start_date&.to_s,
        EndTime: wp.due_date&.to_s,
        Duration: wp.duration&.to_s,
        Remarks: work_package_remark(wp),
        ParentID: wp.parent_id
      }.compact
    end
  end

  def send_by_grpc
    result = Proto::OpService::Service.current_client.call(
      :GetPdf,
      {
        Data: grpc_data,
        Email: user.mail
      }
    )

    @payload[:redirect] = result.message.url
  end

  def logger
    Rails.logger
  end
end
