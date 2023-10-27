module API
  module V3
    module WorkPackageEdocFolders
      class WorkPackageEdocFolderByWorkPackageAPI < ::API::OpenProjectAPI
        resources :edoc_folder do
          after_validation do
            @edoc_folder = WorkPackageEdocFolder.find_by(work_package_id: @work_package.id)
            if @edoc_folder.present?
              ThWorkPackages::PublishEdocFolderJob.perform_now(@edoc_folder.id) unless @edoc_folder.publish_code.present?
            else
              @edoc_folder = ThWorkPackages::CreateEdocFolderJob.perform_now(@work_package.id)
            end
          end

          get do
            WorkPackageEdocFolderRepresenter.create(@edoc_folder, current_user:)
          end
        end
      end
    end
  end
end
