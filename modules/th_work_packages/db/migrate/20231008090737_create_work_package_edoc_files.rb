class CreateWorkPackageEdocFiles < ActiveRecord::Migration[7.0]
  def change
    create_table :work_package_edoc_files do |t|
      t.integer :folder_id, null: false, index: true, comment: '文件夹ID'
      t.integer :file_id, null: false, index:  true, comment: '文件ID'
      t.string :file_name, null: false, comment: '文件名'
      t.string :upload_id, null: false, default: '', comment: '上传ID'
      t.string :md5, null: false, default: '', comment: '文件MD5值'
      t.integer :file_size, null: false, default: 0, comment: '文件大小'
      t.integer :file_ver_id, null: false, default: 0, comment: '文件版本ID'
      t.string :region_hash, limit: 1000, null: false, default: '', comment: '区域上传或更新操作的Hash码'
      t.integer :region_id, null: false, default: 0, comment: '区域编号'
      t.integer :region_type, null: false, default: 1, comment: '区域类型，1：主区域，2：分区域'
      t.string :region_url, null: false, default: '', comment: '区域主机地址'
      t.integer :chunks, null: false, default: 0, comment: '切片总数'
      t.integer :chunk_size, null: false, default: 0, comment: '切片大小'
      t.integer :status, limit: 1, null: false, default: 0, comment: '上传状态，0,1,-1'
      t.timestamps
    end
  end
end
