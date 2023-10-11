module API
  module V3
    module WorkPackageEdocFiles
      class WorkPackageEdocFilesByEdocFolderAPI < ::API::OpenProjectAPI
        resources :files do
          get do
            WorkPackageEdocFileCollectionRepresenter
                .new(@edoc_folder.files,
                     @edoc_folder.files.size,
                     self_link: api_v3_paths.edoc_files_by_work_package_edoc_folder(@edoc_folder.folder_id),
                     current_user: User.current)
          end
        end
      end
    end
  end
end
