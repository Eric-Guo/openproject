class CreateWorkPackageEdocFolders < ActiveRecord::Migration[7.0]
  def change
    create_table :work_package_edoc_folders do |t|
      t.belongs_to :work_package, index: { unique: true }
      t.integer :folder_id, null: false, default: 0, index: true, comment: '文件夹ID'
      t.string :folder_name, null: false, default: '', comment: '文件夹名称'
      t.string :publish_code, null: false, default: '', comment: '外发code'
      t.timestamps
    end
  end
end
