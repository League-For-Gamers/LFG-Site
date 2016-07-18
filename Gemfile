source 'https://rubygems.org'
## Rails Default
gem 'rails', '4.2.7'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'turbolinks', '< 4' # I want to use 5 but jquery-turbolinks does not support it.
gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'bcrypt', '~> 3.1.7'

## Aftermarket rails
gem 'pg', '0.18.4'
gem 'pg_search'
gem 'fog', '~> 1.33', require: 'fog/aws'
gem 'asset_sync'
gem 'redis-rails'
gem 'rails_autolink'

# For env[] management
gem 'figaro'
gem 'httpclient'
gem 'sucker_punch', '~> 2.0'

# For S3 access
gem 'paperclip'
gem 'aws-sdk'
gem 'paperclip-optimizer'

gem 'foundation-rails', '~> 5.5.3.2'

group :staging, :production do
  gem 'puma'
  gem 'newrelic_rpm'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  gem 'rspec-rails', '~> 3.5'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'simplecov', require: false
  gem 'pry-rails'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'quiet_assets'
  gem 'capistrano', '3.5.0', require: false
  gem 'capistrano-bundler', '~> 1.1.4', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano3-puma', require: false
  gem 'ruby-prof'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
