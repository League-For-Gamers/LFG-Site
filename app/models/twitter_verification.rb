class TwitterVerification < ActiveRecord::Base

  def client
    TwitterIntegration.client_for self
  end

end
