Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, TwitterIntegration.api_key, TwitterIntegration.api_secret
end
