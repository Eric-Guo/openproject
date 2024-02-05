class CreateThAnnotationDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :th_annotation_documents do |t|
      t.string :uuid, null: false, default: '', index: true, comment: '文档ID'
      t.string :type, null: false, default: '', index: true, comment: '文档类型'
      t.integer :target_id, null: false, default: 0, index: true, comment: '目标ID'
      t.json :members, null: true, default: nil, comment: '成员列表'
      t.timestamps
    end
  end
end
