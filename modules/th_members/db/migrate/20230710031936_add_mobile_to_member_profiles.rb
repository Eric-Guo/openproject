class AddMobileToMemberProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :member_profiles, :mobile, :string, limit: 100, default: '', null: false
  end
end
