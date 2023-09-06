set :nginx_use_ssl, true
set :branch, :thape_prod
set :rails_env, "production"
set :puma_service_unit_name, :puma_ppm
set :puma_systemctl_user, :system

server "thape_homeland", user: "open_project", roles: %w{app db web}
