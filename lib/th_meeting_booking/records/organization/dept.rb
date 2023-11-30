module ThMeetingBooking::Records::Organization
  # 组织基本信息，示例数据如下
  # ```JSON
  # {
  #   "id": "2V9qmcHLkftPMjzLQsFusF",
  #   "name": "管理层",
  #   "shortName": "管理层",
  #   "fullName": "管理层",
  #   "showOrder": 100,
  #   "labelName": "管理层",
  #   "userCount": 1,
  #   "userCountWithNew": 1,
  #   "path": [
  #     {
  #       "id": "2V9qmcHLkftPMjzLQsFusF",
  #       "name": "管理层",
  #       "showOrder": 1
  #     }
  #   ],
  #   "isSett": true,
  #   "abilities": [
  #     "edit"
  #   ]
  # }
  # ```
  class Dept < ThMeetingBooking::Records::Base
    Fields = [
      :id,
      :name, # 部门名称
      :short_name, # 部门短名字
      :full_name, # 部门全名，长名称
      :show_order, # 部门显示顺序号
      :label_name, # 部门显示名，如果界面上显示，尽量使用labelName
      :user_count, # 直属部门的员工数
      :user_count_with_new, # 直属部门的员工数（包含未激活的用户）
      :path, # 部门结构路径，列表当前部门的所有上级部门，从最顶级部门依次排序
      :upstream_id, # 业务系统部门ID。字符类型，如果业务系统是数字型ID，需要转成string
      :upstream_parent_id, # 业务系统上级部门ID，如果对应的upstreamId没有同步过，则不会归属为子部门。字符类型，如果业务系统是数字型ID，需要转成string
      :deleted, # 删除标识，值为DELETED表示已经删除。
      :is_sett,
      :abilities,
    ]

    attr_accessor(*Fields)

    def path=(value)
      if value.is_a?(Array)
        @path = value.map { |item| Dept.new(item) }
      else
        @path = nil
      end
    end
  end
end
