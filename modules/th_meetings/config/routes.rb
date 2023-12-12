OpenProject::Application.routes.draw do
  resources :th_meetings, only: [] do
    collection do
      get :available_rooms
    end
  end
end
