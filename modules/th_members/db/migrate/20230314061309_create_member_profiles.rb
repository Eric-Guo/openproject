class CreateMemberProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :member_profiles do |t|
      t.integer :member_id, null: false, default: 0, index: { unique: true }
      t.string :company, limit: 2000, default: '', null: false
      t.string :position, limit: 2000, default: '', null: false
      t.string :remark, default: nil, null: true
      t.timestamps
    end
  end
end
