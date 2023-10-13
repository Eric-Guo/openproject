class AddUserIdToWorkPackageEdocFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :work_package_edoc_files, :user_id, :integer, null: true, default: nil, comment: '用户ID'
  end
end
