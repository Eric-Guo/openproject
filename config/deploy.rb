# config valid for current version and patch releases of Capistrano
lock "~> 3.18.0"

set :application, "open_project"
set :repo_url, "https://git.thape.com.cn/rails/openproject.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/open_project
# set :deploy_to, "/var/www/open_project"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# https://github.com/seuros/capistrano-sidekiq#known-issues-with-capistrano-3
set :pty, false

# Default value for :linked_files is []
append :linked_files, *%w[config/configuration.yml config/database.yml config/secrets.yml config/master.key .env config/puma.rb]

# Default value for linked_dirs is []
append :linked_dirs, *%w[files log storage node_modules frontend/node_modules tmp/pids tmp/cache tmp/sockets public/uploads public/system public/packs public/fonts/msyh]

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

set :rbenv_type, :user
set :rbenv_ruby, "3.2.2"

set :puma_init_active_record, true

set :delayed_job_workers, 12
