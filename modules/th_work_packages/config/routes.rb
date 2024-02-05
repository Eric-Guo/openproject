OpenProject::Application.routes.draw do
  scope 'th_work_packages', as: 'th_work_packages' do
    resources :edoc_files,
              controller: 'th_work_packages/edoc_files',
              only: %i[],
              as: :edoc_files do
      member do
        get :annotation_document
      end
    end
  end
end
