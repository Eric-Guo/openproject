module API
  module V3
    module WorkPackageEdocFiles
      class WorkPackageEdocFilesAPI < ::API::OpenProjectAPI
        resources :work_package_edoc_files do
          helpers API::V3::Attachments::AttachmentsByContainerAPI::Helpers

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

            helpers do
              def allowed_content_types
                if post_request?
                  %w(multipart/form-data)
                else
                  super
                end
              end

              def post_request?
                request.env['REQUEST_METHOD'] == 'POST'
              end
            end

            namespace :upload do
              post do
                chunk_index = request.params[:chunk_index].presence
                unless chunk_index.present? && (/^\d+$/ === chunk_index)
                  raise API::Errors::InvalidRequestBody, 'chunk_index是无效值'
                end

                chunk_index = chunk_index.to_i
                unless chunk_index >= 0 && chunk_index < @edoc_file.chunks
                  raise API::Errors::InvalidRequestBody, 'chunk_index是无效值'
                end

                chunk_file = request.params[:chunk_file].presence&.fetch(:tempfile)
                unless chunk_file.present? && chunk_file.class == Tempfile
                  raise API::Errors::InvalidRequestBody, 'chunk_file是无效值'
                end

                if chunk_index == (@edoc_file.chunks - 1)
                  size = @edoc_file.file_size - @edoc_file.chunk_size * (@edoc_file.chunks - 1)
                  unless chunk_file.size == size
                    raise API::Errors::InvalidRequestBody, "#{chunk_index}: 块文件大小错误，应该为: #{size}"
                  end
                else
                  unless chunk_file.size == @edoc_file.chunk_size
                    raise API::Errors::InvalidRequestBody, "#{chunk_index}: 块文件大小错误，应该为: #{@edoc_file.chunk_size}"
                  end
                end

                res = @edoc_file.upload_chunk(chunk_file, chunk_index)

                WorkPackageEdocFileRepresenter.create(res, current_user:)
              end
            end

            namespace do
              delete do
                @edoc_file.destroy!
                { success: true }
              end
            end
          end
        end
      end
    end
  end
end
