OpenProject::Application.routes.draw do
  scope 'projects/:project_id', as: 'project' do
    resource :project_timeline,
              controller: 'th_projects/project_timelines',
              only: %i[show],
              as: :project_timelines

    resource :project_more,
              controller: 'th_projects/project_more',
              only: %i[show],
              as: :project_more
  end
end
