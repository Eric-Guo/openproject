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

          namespace :create do
            post &::API::V3::Utilities::Endpoints::Create.new(
                                                              model: WorkPackageEdocFile,
                                                              parse_service: WorkPackageEdocFiles::ParseParamsService,
                                                              params_modifier: ->(params) {
                                                                params.merge(folder_id: @edoc_folder.folder_id)
                                                              }
                                                             ).mount
          end
        end
      end
    end
  end
end
