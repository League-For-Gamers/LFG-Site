class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_current_user, if: :logged_in?

  def logged_in?
    !!session[:user]
  end

  def login_user(user)
    session[:user] = user.id
  end

  def logout_user
    session.delete :user
  end

  private
    def set_current_user
      @current_user = User.find session[:user]
    end

    def not_found
      raise ActionController::RoutingError.new('Not Found')
    end
end
