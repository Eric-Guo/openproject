set :application, "open_project"
set :user, "open_project"
set :nginx_use_ssl, true
set :branch, :new_dev
set :rails_env, "production"
set :puma_service_unit_name, :puma_ppm
set :puma_systemctl_user, :system

server "thape_ppp", user: "open_project", roles: %w{app db web}
