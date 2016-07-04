class OmniController < ApplicationController
  def create
    raise [auth_hash[:extra][:access_token].to_json].inspect
    redirect_to '/'
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
