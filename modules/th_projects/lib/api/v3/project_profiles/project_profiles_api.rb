module API
  module V3
    module ProjectProfiles
      class ProjectProfilesAPI < ::API::OpenProjectAPI
        resources :project_profiles do
          get &::API::V3::Utilities::Endpoints::SqlFallbackedIndex.new(model: ProjectProfile,
                                                                       scope: -> {
                                                                          ProjectProfile
                                                                            .includes(ProjectProfileRepresenter.to_eager_load)
                                                                       })
                                                                  .mount

          post &::API::V3::Utilities::Endpoints::Create.new(model: ProjectProfile)
                                                                  .mount

          params do
            requires :id, desc: 'Project profile id'
          end
          route_param :id do
            after_validation do
              @project_profile = ProjectProfile.find(params[:id])

              @project = if current_user.admin?
                           Project.all
                         else
                           Project.visible(current_user)
                         end.find(@project_profile.project_id)
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: ProjectProfile).mount
            patch &::API::V3::Utilities::Endpoints::Update.new(model: ProjectProfile).mount
          end
        end
      end
    end
  end
end
