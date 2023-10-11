module API
  module V3
    module WorkPackageEdocFiles
      class WorkPackageEdocFilesAPI < ::API::OpenProjectAPI
        resources :work_package_edoc_files do
          route_param :id, type: Integer, desc: 'edoc folder ID' do
            after_validation do
              @edoc_file = WorkPackageEdocFile.find_by!(file_id: params[:id])

              @edoc_folder = WorkPackageEdocFolder.find_by!(folder_id: @edoc_file.folder_id)

              @work_package = WorkPackage.find(@edoc_folder.work_package_id)

              authorize(:view_work_packages, context: @work_package.project) do
                raise API::Errors::NotFound.new model: :work_package
              end
            end

            get do
              WorkPackageEdocFileRepresenter.create(@edoc_file, current_user:)
            end
          end
        end
      end
    end
  end
end
