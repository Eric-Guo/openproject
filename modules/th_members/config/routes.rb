OpenProject::Application.routes.draw do
  scope 'th_members', as: 'th_members' do
    resources :member_profiles,
              controller: 'th_members/member_profiles',
              only: %i[update],
              as: :member_profiles do
    end
  end
end
