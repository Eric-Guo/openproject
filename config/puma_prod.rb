#!/usr/bin/env puma

directory '/var/www/open_project/current'
rackup "/var/www/open_project/current/config.ru"
environment 'production'

tag ''

pidfile "/var/www/open_project/shared/tmp/pids/puma.pid"
state_path "/var/www/open_project/shared/tmp/pids/puma.state"
stdout_redirect '/var/www/open_project/shared/log/puma_access.log', '/var/www/open_project/shared/log/puma_error.log', true

threads 5, 16

bind 'unix:///var/www/open_project/shared/tmp/sockets/puma.sock'

workers 7

restart_command 'bundle exec puma'

prune_bundler

on_restart do
  puts 'Refreshing Gemfile'
  ENV["BUNDLE_GEMFILE"] = ""
end
