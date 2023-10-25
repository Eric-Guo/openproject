class AddMajorToMemberProfile < ActiveRecord::Migration[7.0]
  def change
    add_column :member_profiles, :major, :string, limit: 250, default: '', null: false
  end
end
