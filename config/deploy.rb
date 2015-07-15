APP_CONFIG = YAML.load_file("config/application.yml")
# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'LeagueForGamers'
set :repo_url, APP_CONFIG['GIT_REPO'] # Keeping the current git repo hidden for when we launch on github
set :branch, 'master'
set :use_sudo, true

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/var/www/lfg'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/application.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/sessions', 'tmp/sockets','tmp/pids', 'vendor/bundle')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :ssh_options, { keys: [APP_CONFIG['SSH_KEY_DIR']] }

# Puma configuration
set :puma_threads, [0, 4]
set :puma_workers, 4
set :puma_init_active_record, true
set :puma_preload_app, true

namespace :deploy do

  desc "Transfer application.yml to server"
  task :transfer_config do
    on roles(:app) do
      upload! "config/database.#{fetch(:rails_env)}.yml", "#{shared_path}/config/database.yml"
      upload! "config/application.#{fetch(:rails_env)}.yml", "#{shared_path}/config/application.yml"
    end
  end

  desc "Symlink the nginx config"
  task :symlink_nginx do
    on roles(:app) do
      execute :sudo, "ln -nfs #{current_path}/config/nginx.#{fetch(:rails_env)}.conf /etc/nginx/sites-enabled/#{fetch(:application)}-#{fetch(:rails_env)}.conf"
      execute :sudo, "systemctl reload nginx" # Not pretty...
    end
  end

  after :publishing, :symlink_nginx

  before "deploy:check:linked_files", :transfer_config

  desc "Invoke rake task"
  task :invoke_task do
    ask :task, nil
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, fetch(:task)
        end
      end 
    end
  end
  task :gzip_assets do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'assets:gzip'
        end
      end
    end
  end
  after 'deploy:compile_assets', :gzip_assets
end

namespace :bundler do
  desc 'Set Nokogiri config flags'
  task :noko_config do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          # Otherwise builds take for fucking ever.
          execute :bundle, "config build.nokogiri --use-system-libraries"
        end
      end
    end
  end

  before :install, :noko_config
end