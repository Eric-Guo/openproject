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

    resources :annotation_documents,
              controller: 'th_work_packages/annotation_documents',
              only: %i[],
              as: :annotation_documents do
      collection do
        post :callback
      end
    end
  end
end
