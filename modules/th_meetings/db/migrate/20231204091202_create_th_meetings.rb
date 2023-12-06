class CreateThMeetings < ActiveRecord::Migration[7.0]
  def change
    create_table :th_meetings do |t|
      t.belongs_to :meeting, null: false, index: true
      t.string :th_meeting_id, null: false, default: '', comment: '会议ID'
      t.string :upstream_id, null: false, default: '', comment: '业务系统预订ID'
      t.string :upstream_area_id, null: false, default: '', comment: '业务系统区域ID'
      t.string :upstream_area_name, null: false, default: '', comment: '业务系统区域名称'
      t.string :upstream_room_id, null: false, default: '', comment: '业务系统资源ID'
      t.string :upstream_room_name, null: false, default: '', comment: '业务系统资源名称'
      t.string :booking_user_id, null: false, default: '', comment: '业务系统人员ID'
      t.string :booking_user_name, null: false, default: '', comment: '预订人姓名'
      t.string :booking_user_email, null: false, default: '', comment: '预订人邮箱'
      t.string :booking_user_phone, null: false, default: '', comment: '预订人电话'
      t.string :subject, null: false, default: '', limit: 500, comment: '预订主题'
      t.string :content, null: false, default: '', limit: 10000, comment: '预订内容'
      t.string :begin_time, null: false, default: '', limit: 20, comment: '开始时间，格式：YYYY-MM-DD HH:mm:ss'
      t.string :end_time, null: false, default: '', limit: 20, comment: '结束时间，格式：YYYY-MM-DD HH:mm:ss'
      t.json :members, null: true, default: nil, comment: '成员'
    end
  end
end
