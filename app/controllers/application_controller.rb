class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_current_user, if: :logged_in?
  before_action :login_from_token, unless: :logged_in?

  private
    def set_title(page_title)
      @title = "#{page_title} — League For Gamers"
    end

    def logged_in?
      !!session[:user]
    end

    def login_user(user)
      session[:user] = user.id
    end

    def remember_user(user, request)
      t = Time.now
      auth = "#{user.id},#{request.ip},#{t.yday}#{t.year}"
      hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, ENV['SECRET_TOKEN'], auth)
      cookies[:remember] = { value: "#{user.id}:#{hmac}", expires: 3.weeks.from_now }
    end

    def login_from_token()
      if !!cookies[:remember]
        auth = cookies[:remember].split(':')
        valid = false
        21.times do |i| # 3 weeks
          t = Time.now - i.days
          a = "#{auth[0]},#{request.ip},#{t.yday}#{t.year}"
          hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, ENV['SECRET_TOKEN'], a)
          valid = true and break if hmac == auth[1]
        end
        if valid
          u = User.find(auth[0])
          login_user(u)
          remember_user(u, request) # Validate the token for another 3 weeks.
          redirect_to request.referrer || request.path || root_url
        else
          cookies.delete :remember
        end
      end
    end

    def logout_user
      session.delete :user
      cookies.delete :remember
    end

    def set_current_user
      @current_user ||= User.includes(:follows, :bans, role: [:permissions]).find session[:user]
      # Unban mechanism
      if @current_user.role.name == "banned" 
        if @current_user.bans.first.end_date != nil and @current_user.bans.first.end_date < Time.now 
          @current_user.role = @current_user.bans.first.role
          @current_user.save
        else
          @ban = @current_user.bans.first
        end
      end
    end

    def not_found
      raise ActionController::RoutingError.new('Not Found')
    end

    def required_log_in
      redirect_to '/signup' and return unless logged_in?
    end

    def required_logged_out
      redirect_to root_url and return if logged_in?
    end
end
