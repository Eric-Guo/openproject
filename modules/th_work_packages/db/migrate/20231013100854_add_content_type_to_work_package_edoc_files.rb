class AddContentTypeToWorkPackageEdocFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :work_package_edoc_files, :content_type, :string, null: false, default: '', comment: '文件类型'
  end
end
