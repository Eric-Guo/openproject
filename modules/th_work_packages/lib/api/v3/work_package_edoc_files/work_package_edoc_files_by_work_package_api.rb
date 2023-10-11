module API
  module V3
    module WorkPackageEdocFiles
      class WorkPackageEdocFilesByWorkPackageAPI < ::API::OpenProjectAPI
        resources :edoc_files do
          get do
            WorkPackageEdocFileCollectionRepresenter
                .new(@work_package.edoc_files,
                     @work_package.edoc_files.size,
                     self_link: api_v3_paths.edoc_files_by_work_package(@work_package.id),
                     current_user: User.current)
          end
        end
      end
    end
  end
end
