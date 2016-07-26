class OmniController < ApplicationController
  def create
    record_the_twitter_verification

    set_the_current_users_twitter_name_to raw_info.screen_name

    redirect_to '/account', notice: "Twitter account authenticated"
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

  private

  def record_the_twitter_verification
    TwitterVerification.create(user_id: @current_user.id,
                               secret: access_token.secret,
                               token: access_token.token,
                               screen_name: raw_info.screen_name)
  end

  def set_the_current_users_twitter_name_to name
    @current_user.social['link_twitter'] = name
    @current_user.save
  end
end
