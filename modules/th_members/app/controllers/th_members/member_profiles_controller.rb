module ::ThMembers
  class MemberProfilesController < ::MembersController
    def update
      profile = @member.profile || MemberProfile.new({ member_id: @member.id })

      update_params.each do |key, value|
        profile[key] = value
      end

      if profile.save
        display_success(I18n.t(:notice_successful_update))
      else
        display_error(service_call)
      end

      redirect_to project_members_path(project_id: @project,
                                       page: params[:page],
                                       per_page: params[:per_page])
    end

    private
      def update_params
        params.require(:member).permit(*MemberProfile.service_columns)
      end
  end
end
