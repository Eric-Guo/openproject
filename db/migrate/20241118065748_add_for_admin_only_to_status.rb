class AddForAdminOnlyToStatus < ActiveRecord::Migration[7.1]
  def change
    add_column :types, :is_admin_only, :boolean, null: false, default: false
  end
end
