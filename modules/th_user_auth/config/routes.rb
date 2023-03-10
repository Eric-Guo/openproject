OpenProject::Application.routes.draw do
  scope 'th_user_auth', as: 'th_user_auth' do
    resource :api_key,
              controller: 'th_user_auth/api_keys',
              only: %i[show],
              as: :api_key do
    end
  end
end
