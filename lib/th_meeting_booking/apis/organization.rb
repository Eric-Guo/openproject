module ThMeetingBooking::Apis
  class Organization < Base
    # 组织基本信息
    # 读取当前组织基本信息和授权信息等，可用于测试可用性。
    # @return [Array[ThMeetingBooking::Records::Organization::Info]]
    def self.info
      result = ThMeetingBooking::Request.new.get('info')
      ThMeetingBooking::Records::Organization::Info.new(result[:data])
    end

    # 全量读取部门数据
    # 读取部门数据。
    # 按参数strut返回部门数据。struct取值如下：
    # * list: 返回平铺列表数据；无struct参数时也将返回平铺列表数据
    # * tree: 返回树形部门数据
    # @param struct [String] 返回数据的结构，支持：tree 树形结构 / list 平铺列表结构。默认不传值是返回list平铺列表结构
    # @return [ThMeetingBooking::Records::Organization::DeptList]
    def self.depts(struct = 'list')
      result = ThMeetingBooking::Request.new.get('depts', params: { struct: })
      ThMeetingBooking::Records::Organization::DeptList.new(result)
    end

    # 读取子部门列表
    # 读取parentId对应部门的直属下级部门。
    # parentId 为部门ID，如果值为 0 ，则返回所有顶级部门
    # @param parent_id [String] 上级部门ID，只会返回此部门直属的子部门列表；传0值，将返回所有顶级部门
    # @return [ThMeetingBooking::Records::Organization::DeptList]
    def self.child_depts(parent_id = 0)
      result = ThMeetingBooking::Request.new.get('depts', params: { parentId: parent_id })
      ThMeetingBooking::Records::Organization::DeptList.new(result)
    end


    # 同步部门（新增或修改）
    # 需求：部门数据在业务系统中，需要把业务系统的部门结构数据同步到预订系统。
    # 业务系统的部门ID作为upstreamId，同步时，预订系统检查同一upstreamId是否已经同步过，如果没同步过则新增部门；如果已经存在upstreamId对应的部门，则修改对应的部门信息。
    # 对于下级部门，同步数据中通过upstreamParentId，传入对应上级部门的业务系统ID，预订系统将依据此参数建立部门上下级结构。 如果upstreamParentId对应的部门之前没有同步过，则不会归属为子部门；但下次同步时会继续检查上级部门是否已经建立。 所以建议先同步父部门，再同步子部门。
    # @param upstream_id: [String] 业务系统部门ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param name: [String] 部门名
    # @param upstream_parent_id: [String] 业务系统上级部门ID，如果对应的upstreamId没有同步过，则不会归属为子部门。字符类型，如果业务系统是数字型ID，需要转成string
    # @param show_order: [String] 显示顺序号，部门排序按从小到大排序
    # @return [ThMeetingBooking::Records::Organization::Dept]
    def self.sync_depts(upstream_id:, name:, upstream_parent_id: nil, show_order: nil)
      data = {
        upstreamId: upstream_id,
        name:,
        upstreamParentId: upstream_parent_id,
        showOrder: show_order,
      }
      result = ThMeetingBooking::Request.new.post('sync-depts', data:)
      ThMeetingBooking::Records::Organization::Dept.new(result[:data])
    end

    # 同步部门（删除）
    # 需求：部门数据在业务系统中，需要把业务系统的部门结构数据同步到预订系统。
    # 业务系统的部门ID作为upstreamId，同步删除时，预订系统检查同一upstreamId是否已经同步，只有在已经同步时，才会删除对应的部门。 注意，预订系统在同步删除父部门后，子部门不会自动删除，需要继续调用子部门的删除操作。 如果父部门删除后，没有调用子部门的删除，则子部门会成为顶级部门。
    # @param upstream_id [String] 业务系统部门ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param name [String] 部门名称
    # @return [ThMeetingBooking::Records::Organization::Dept]
    def self.remove_sync_dept(upstream_id:, name:)
      data = {
        upstreamId: upstream_id,
        name:,
        deleted: 1,
      }
      result = ThMeetingBooking::Request.new.post('sync-depts', data:)
      ThMeetingBooking::Records::Organization::Dept.new(result[:data])
    end

    # 同步人员（新增或修改）
    # 需求：人员数据在业务系统中，需要把业务系统的人员及所属部门结构数据同步到预订系统。
    # 业务系统的人员ID作为upstreamId，同步时，预订系统检查同一upstreamId是否已经同步过，如果没同步过则新增人员；如果已经存在upstreamId对应的人员，则修改对应的人员信息。
    # 需要先调用同步所有部门后，之后再调用同步人员，以保证同步的人员所属部门信息存在。
    # @param upstream_id: [String] 业务系统人员ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param name: [String] 人员姓名
    # @param upstream_dept_id: [String] 所属部门在业务系统的ID，如果业务系统是数字型ID，需要转成string
    # @param email: [String] 电子邮箱，比如 example@qq.com
    # @param mobile: [String] 手机号码
    # @param login_name: [String] 登录名，如果无，可以直接传upsteamId
    # @return [ThMeetingBooking::Records::Organization::User]
    def self.sync_users(upstream_id:, name:, upstream_dept_id:, email: nil, mobile: nil, login_name: nil)
      data = {
        upstreamId: upstream_id,
        name: name,
        upstreamDeptId: upstream_dept_id,
        email: email,
        mobile: mobile,
        loginName: login_name || upstream_id,
      }
      result = ThMeetingBooking::Request.new.post('sync-users', data:)
      ThMeetingBooking::Records::Organization::User.new(result[:data])
    end

    # 同步人员（删除）
    # 需求：人员数据在业务系统中，需要把业务系统的人员调整信息同步到预订系统。
    # 业务系统的人员ID作为upstreamId，同步删除时，预订系统检查同一upstreamId是否已经同步，只有在已经同步时，才会删除对应的人员。
    # @param upstream_id: [String] 业务系统部门ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param name: [String] 人员姓名
    # @return [ThMeetingBooking::Records::Organization::User]
    def self.remove_sync_user(upstream_id:, name:)
      data = {
        upstreamId: upstream_id,
        name:,
        deleted: 1,
      }
      result = ThMeetingBooking::Request.new.post('sync-user', data:)
      ThMeetingBooking::Records::Organization::User.new(result[:data])
    end

    # 同步人员人脸照片
    # @param upstream_id: [String] 业务系统部门ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @param face: [String] 人脸照片base64值；如果要删除人脸，不需要传face参数
    # @return [ThMeetingBooking::Records::Organization::User]
    def self.sync_face(upstream_id:, face:)
      data = {
        upstreamId: upstream_id,
        face:,
        deleted: 0,
      }
      result = ThMeetingBooking::Request.new.post('sync-face', data:)
      ThMeetingBooking::Records::Organization::User.new(result[:data])
    end

    # 同步人员人脸照片（删除）
    # @param upstream_id [String] 业务系统部门ID。字符类型，如果业务系统是数字型ID，需要转成string
    # @return [ThMeetingBooking::Records::Organization::User]
    def self.remove_sync_face(upstream_id)
      data = {
        upstreamId: upstream_id,
        deleted: 1,
      }
      result = ThMeetingBooking::Request.new.post('sync-face', data:)
      ThMeetingBooking::Records::Organization::User.new(result[:data])
    end
  end
end
