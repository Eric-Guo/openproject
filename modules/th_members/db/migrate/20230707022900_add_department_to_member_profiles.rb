class AddDepartmentToMemberProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :member_profiles, :department, :string, limit: 2000, default: '', null: false
  end
end
