class UsersController < ApplicationController
  before_action :set_user, only: [:show]

  # GET /login
  def login
    flash[:notice] = "Already logged in." and redirect_to root_url and return if logged_in?
  end

  # POST /login
  def login_check
    user = User.find_by(username: login_params[:username]).try(:authenticate, login_params[:password])

    unless user.nil? or !user # Nil if there's no results, false if failed authentication
      login_user(user)
      flash[:notice] = "Successfully logged in."
      redirect_to root_url
    else
      flash[:alert] = "Invalid username or password."
      render "login"
    end
  end

  def logout
    flash[:notice] = "Successfully logged out"
    logout_user and redirect_to root_url
  end
  
  def signup
    @user = User.new
  end

  # GET /user/account
  def my_account
    redirect_to root_url and return unless logged_in?
  end

  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        login_user(@user)
        format.html { redirect_to "/user/#{@user.id}", notice: 'User was successfully created.' }
        format.json { render action: 'show', status: :created, location: @user }
      else
        format.html { render action: 'signup' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /user/account
  def update
    respond_to do |format|
      if @current_user.update(user_params)
        format.html { render action: 'my_account', notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'my_account' }
        format.json { render json: @current_user.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def login_params
      params.permit(:username, :password)
    end

    def user_params
      params.require(:user).permit(:username, :old_password, :password, :password_confirmation, :email, :bio, :display_name, :avatar)
    end
end
