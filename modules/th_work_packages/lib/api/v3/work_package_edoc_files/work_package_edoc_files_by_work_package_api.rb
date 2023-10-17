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

          namespace :create do
            post &::API::V3::Utilities::Endpoints::Create.new(
                                                              model: WorkPackageEdocFile,
                                                              parse_service: WorkPackageEdocFiles::ParseParamsService,
                                                              params_modifier: ->(params) {
                                                                params.merge(folder_id: @work_package.edoc_folder.folder_id)
                                                              }
                                                             ).mount
          end
        end
      end
    end
  end
end
