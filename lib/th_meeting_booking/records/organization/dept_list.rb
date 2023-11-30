module ThMeetingBooking::Records::Organization
  # 部门列表
  class DeptList < ThMeetingBooking::Records::Base
    Fields = [
      :data, # 部门列表
      :sumary, # 统计数据
    ]

    attr_accessor(*Fields)

    def data=(value)
      if value.is_a?(Array)
        @data = value.map { |item| Dept.new(item) }
      else
        @data = nil
      end
    end

    def sumary=(value)
      if value.present?
        @sumary = DeptSumary.new(value)
      else
        @sumary = nil
      end
    end
  end
end
