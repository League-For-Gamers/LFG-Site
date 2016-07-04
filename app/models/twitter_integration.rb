module TwitterIntegration

  def self.api_key
    ENV["TWITTER_API_KEY"]
  end

  def self.api_secret
    ENV["TWITTER_API_SECRET"]
  end

  def self.client_for verification
    Twitter::REST::Client.new do |config|
      config.consumer_key        = api_key
      config.consumer_secret     = api_secret
      config.access_token        = verification.token
      config.access_token_secret = verification.secret
    end
  end

end
