module ThMeetingBooking::Records::Approving
  # 审批列表
  class ApproveList < ThMeetingBooking::Records::Base
    Fields = [
      :data,
      :page_size,
      :page_number,
      :total_page,
      :total_count,
      :has_next_page,
      :has_previous_page,
      :page_params,
    ]

    attr_accessor(*Fields)

    def data=(value)
      if value.is_a?(Array)
        @data = value.map { |item| Approve.new(item) }
      else
        @data = nil
      end
    end

    def page_params=(value)
      if value.present?
        @page_params = ApprovePageParams.new(value)
      else
        @page_params = nil
      end
    end
  end
end
