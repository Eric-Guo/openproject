module ThWorkPackages
  class AnnotationDocumentsController < ::ApplicationController
    skip_before_action :verify_authenticity_token

    def callback
      service = get_callback_class(params[:msgType])

      service.new(params).call

      render json: {
        message: '回调成功'
      }
    rescue StandardError => e
      render status: :bad_request, json: {
        message: "回调失败，错误信息见error",
        error: e.message
      }
    end

    private

    # 获取回调类
    def get_callback_class(type_name)
      "ThAnnotationDocuments::Callbacks::#{type_name.camelize}".constantize
    end
  end
end
