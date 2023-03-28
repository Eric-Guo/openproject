class CreateProjectProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :project_profiles do |t|
      t.integer :project_id, null: false, default: 0, index: { unique: true }
      t.integer :type_id, limit: 1, null: false, default: 0, index: true, comment: '项目类型'
      t.string :code, null: false, default: '', index: true, comment: '项目编号'
      t.string :name, limit: 2000, null: false, default: '', comment: '项目名称'
      t.string :doc_link, limit: 2000, null: false, default: '', comment: '文档链接'
      t.timestamps
    end
  end
end
