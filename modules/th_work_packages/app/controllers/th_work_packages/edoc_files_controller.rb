module ThWorkPackages
  class EdocFilesController < ::ApplicationController
    def annotation_document
      edoc_file = WorkPackageEdocFile.find(params[:id])

      document = edoc_file.annotation_document || edoc_file.create_annotation_document

      render status: 404, html: '未查询到标注文档' unless document.present?

      document.sync_members

      user_token = ThAnnotator::Apis::Base.get_user_token(email: current_user.mail)

      url = ThAnnotator::Helpers.jump_url(token: user_token, uuid: document.uuid)

      redirect_to url
    end
  end
end
