class CreateTokenPlainTexts < ActiveRecord::Migration[7.0]
  def change
    create_table :token_plain_texts do |t|
      t.integer :token_id, default: 0, null: false, index: { unique: true }
      t.string :value, default: "", null: false, limit: 128
      t.timestamps
    end
  end
end
