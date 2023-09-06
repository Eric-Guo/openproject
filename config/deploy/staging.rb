set :nginx_use_ssl, true
set :branch, :eric_dev
set :rails_env, "production"
set :puma_service_unit_name, :puma_plm
set :puma_systemctl_user, :system

server "thape_plm", user: "open_project", roles: %w{app db web}
