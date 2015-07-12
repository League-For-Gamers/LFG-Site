source 'https://rubygems.org'
## Rails Default
gem 'rails', '4.2.3'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'turbolinks'
gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'bcrypt', '~> 3.1.7'

## Aftermarket rails
gem 'pg', '0.18.2'
gem 'pg_search'
gem 'redcarpet'
gem 'fog', '~> 1.32', require: 'fog/aws'
gem 'asset_sync'
gem 'redis-rails'

# For env[] management
gem 'figaro'
gem 'httpclient'

# For S3 access
gem 'paperclip'
gem 'aws-sdk', '< 2.0'

# Temporary. Blank pages are boring.
gem 'foundation-rails'

group :staging, :production do
  gem 'puma'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  gem 'rspec-rails', '~> 3.3.2'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'simplecov', require: false
  gem 'pry-rails'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'quiet_assets'
  gem 'capistrano', '3.4.0', require: false
  gem 'capistrano-bundler', '1.1.4', require: false
  gem 'capistrano-rails', '1.1.3', require: false
  gem 'capistrano3-puma', require: false
  gem 'ruby-prof'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
