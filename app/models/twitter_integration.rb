module TwitterIntegration

  def self.api_key
    ENV["TWITTER_API_KEY"]
  end

  def self.api_secret
    ENV["TWITTER_API_SECRET"]
  end

end
