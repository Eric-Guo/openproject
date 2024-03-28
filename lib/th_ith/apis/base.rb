module ThIth::Apis
  class Base
    class << self
      # 项目合同列表
      # @param project_id [String] OP项目ID
      # @return [Array] 合同列表
      def project_contracts(project_id)
        result = ThIth::Request.new.get("projects/#{project_id}/contracts")

        (result[:data] || []).map do |contract|
          {
            code: contract[:contractCode],
            name: contract[:contractName],
            date: contract[:filingtime]
          }
        end
      end

      # 项目合同付款节点列表
      # @param project_id [String] OP项目ID
      # @return [Array] 付款节点列表
      def project_contract_payment_nodes(project_id, contract_code:)
        params = {
          contractCode: contract_code
        }

        result = ThIth::Request.new.get("projects/#{project_id}/nodes", params:)

        (result[:data] || []).map do |node|
          {
            date: node[:date],
            title: node[:description]
          }
        end
      end
    end
  end
end
