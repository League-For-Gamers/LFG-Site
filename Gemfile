source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

## Rails Default
gem 'rails', '~> 5.1.4'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2.2'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'turbolinks', '< 5' # I want to use 5 but jquery-turbolinks does not support it.
gem 'jbuilder', '~> 2.5'
gem 'bcrypt', '~> 3.1.7'
gem 'redis', '~> 4.0'

## Aftermarket rails
gem 'pg', '~> 0.21'
gem 'pg_search'
gem 'asset_sync'
gem 'fog-aws'
gem 'redis-rails'
gem 'rails_autolink'
gem 'mime-types'

# For env[] management
gem 'figaro'
gem 'httpclient'
gem 'sucker_punch', '~> 2.0'

# For S3 access
gem 'paperclip', "~> 5.1.0"
gem 'aws-sdk'
gem 'paperclip-optimizer'

gem 'foundation-rails', '~> 5.5.3.2'

group :staging, :production do
  gem 'puma'
  #gem 'newrelic_rpm'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  gem 'rspec-rails', '~> 3.7'
  gem 'rails-controller-testing'
  gem 'factory_bot_rails'
  gem 'database_cleaner'
  gem 'simplecov', require: false
  gem 'pry-rails'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'capistrano', '3.10.1', require: false
  gem 'capistrano-bundler', '~> 1.3.0', require: false
  gem 'capistrano-rails', '~> 1.3.1', require: false
  gem 'ruby-prof'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
