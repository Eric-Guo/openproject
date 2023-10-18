module API
  module V3
    module WorkPackageEdocFolders
      class WorkPackageEdocFolderByWorkPackageAPI < ::API::OpenProjectAPI
        resources :edoc_folder do
          after_validation do
            @edoc_folder = WorkPackageEdocFolder.find_by(work_package_id: @work_package.id) || ThWorkPackages::CreateEdocFolderJob.perform_now(@work_package.id)
          end

          get do
            WorkPackageEdocFolderRepresenter.create(@edoc_folder, current_user:)
          end
        end
      end
    end
  end
end
