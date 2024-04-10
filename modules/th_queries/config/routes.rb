OpenProject::Application.routes.draw do
  resources :th_queries, only: %i[] do
    collection do
      post :export_pdf
    end
  end
end
