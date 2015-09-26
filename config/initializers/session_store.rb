# Be sure to restart your server when you modify this file.

if Rails.env.production? or Rails.env.staging?
  Rails.application.config.session_store :redis_store, servers: ENV['REDIS_SESSION_ADDRESS'], expire_in: 86400 # 1 day
else
  Rails.application.config.session_store :cookie_store, key: '_LeagueForGamers_session'
end