class OmniController < ApplicationController
  def create
    TwitterVerification.create(user_id: @current_user.id,
                               secret: access_token.secret,
                               token: access_token.token,
                               screen_name: raw_info.screen_name)
    redirect_to '/account'
  end

  protected

  def access_token
    auth_hash[:extra][:access_token]
  end

  def raw_info
    auth_hash[:extra][:raw_info]
  end

  def auth_hash
    request.env['omniauth.auth']
  end
end
