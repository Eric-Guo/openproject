module ::ThMembers
  class CompanyFormCell < ::RailsCell
    include RemovedJsHelpersHelper

    options :row, :params, :company

    def member
      model
    end

    def form_url
      url_for form_url_hash
    end

    def form_url_hash
      {
        controller: '/th_members/member_profiles',
        action: 'update',
        id: member.id,
        page: params[:page],
        per_page: params[:per_page]
      }
    end
  end
end
