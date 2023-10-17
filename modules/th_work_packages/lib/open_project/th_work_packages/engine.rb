# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::ThWorkPackages
  class Engine < ::Rails::Engine
    engine_name :openproject_th_work_packages

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-th_work_packages',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 6.0.0'

    patches %i[WorkPackage API::V3::WorkPackages::WorkPackageRepresenter]

    add_api_path :edoc_folder_by_work_package do |id|
      "#{root}/work_packages/#{id}/edoc_folder"
    end

    add_api_path :work_package_edoc_folder do |id|
      "#{root}/work_package_edoc_folders/#{id}"
    end

    add_api_path :edoc_files_by_work_package do |id|
      "#{root}/work_packages/#{id}/edoc_files"
    end

    add_api_path :edoc_files_by_work_package_edoc_folder do |id|
      "#{root}/work_package_edoc_folders/#{id}/files"
    end

    add_api_path :work_package_edoc_file do |id|
      "#{root}/work_package_edoc_files/#{id}"
    end

    add_api_path :create_edoc_file_by_work_package_edoc_folder do |id|
      "#{root}/work_package_edoc_folders/#{id}/files/create"
    end

    add_api_path :create_edoc_file_by_work_package do |id|
      "#{root}/work_packages/#{id}/edoc_files/create"
    end

    add_api_path :upload_work_package_edoc_file do |id|
      "#{root}/work_package_edoc_files/#{id}/upload"
    end

    add_api_endpoint 'API::V3::WorkPackages::WorkPackagesAPI', :id do
      mount ::API::V3::WorkPackageEdocFolders::WorkPackageEdocFolderByWorkPackageAPI
      mount ::API::V3::WorkPackageEdocFiles::WorkPackageEdocFilesByWorkPackageAPI
    end

    add_api_endpoint 'API::V3::Root' do
      mount ::API::V3::WorkPackageEdocFolders::WorkPackageEdocFoldersAPI
      mount ::API::V3::WorkPackageEdocFiles::WorkPackageEdocFilesAPI
    end
  end
end
