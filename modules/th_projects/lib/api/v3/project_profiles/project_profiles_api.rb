module API
  module V3
    module ProjectProfiles
      class ProjectProfilesAPI < ::API::OpenProjectAPI
        resources :project_profiles do
          params do
            requires :code, desc: '项目编号'
          end
          route_param :code do
            after_validation do
              @project_profile = ProjectProfile.joins(:project).find_by(code: params[:code]) || ProjectProfile.new
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: ProjectProfile).mount
          end
        end
      end
    end
  end
end
