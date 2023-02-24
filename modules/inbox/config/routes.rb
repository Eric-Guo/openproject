OpenProject::Application.routes.draw do
  scope 'projects/:project_id', as: 'project' do
    resources :inboxes,
              controller: 'inbox/inboxes',
              only: %i[index],
              as: :inboxes do
    end
  end
end
