module ::ThProjects
  class PaymentNodesController < ApplicationController
    def index
      contracts = ThIth::Apis::Base.project_contracts(params[:project_id])

      contracts.each do |contract|
        contract[:payment_nodes] = ThIth::Apis::Base.project_contract_payment_nodes(params[:project_id], contract_code: contract[:code])
      end

      render json: contracts
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end
end
