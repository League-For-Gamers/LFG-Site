class OmniController < ApplicationController
  def create
    raise [access_token.token, access_token.secret, raw_info.screen_name].inspect
    redirect_to '/'
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
