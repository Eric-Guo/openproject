if Rails.env.production? && ENV["OPENPROJECT_HOST__NAME"] == "plm.thape.com.cn"
  RorVsWild.start(
    api_key: Rails.application.credentials.rorvswild_api_key,
    ignore_requests: %w[
      AccountController#login
      AngularController#empty_layout
      API::ThNonProjectTimeEntriesController#create
      CustomStylesController#favicon_download
      CustomStylesController#touch_icon_download
      HighlightingController#styles
      HomescreenController#index
      Projects::QueriesController#configure_view_modal
      ProjectsController#export_list_modal
      ProjectsController#index
      ThKeyinsController#create
      ThKeyinsController#show
      WorkPackages::ActivitiesTabController#update_streams
    ],
    ignore_jobs: %w[
      Notifications::WorkflowJob
      ThProject::FillRealPmCodeJob
      LdapGroups::SynchronizationJob
    ],
    ignore_exceptions: [],
    ignore_plugins: %w[
      DelayedJob
      Elasticsearch
      Faktory
      Mongo
      Resque
      Sidekiq
    ]
  )
end
