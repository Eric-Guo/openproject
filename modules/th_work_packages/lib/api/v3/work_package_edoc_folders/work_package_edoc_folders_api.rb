module API
  module V3
    module WorkPackageEdocFolders
      class WorkPackageEdocFoldersAPI < ::API::OpenProjectAPI
        resources :work_package_edoc_folders do
          route_param :id, type: Integer, desc: 'edoc folder ID' do
            after_validation do
              @edoc_folder = WorkPackageEdocFolder.find_by!(folder_id: params[:id])

              @work_package = WorkPackage.find(@edoc_folder.work_package_id)

              authorize(:view_work_packages, context: @work_package.project) do
                raise API::Errors::NotFound.new model: :work_package
              end
            end

            get do
              WorkPackageEdocFolderRepresenter.create(@edoc_folder, current_user:)
            end

            mount ::API::V3::WorkPackageEdocFiles::WorkPackageEdocFilesByEdocFolderAPI
          end
        end
      end
    end
  end
end
