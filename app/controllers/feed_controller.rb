class FeedController < ApplicationController
  before_action :set_post, only: [:show, :ban]
  before_action :set_user, only: [:user_feed, :show]
  before_action :required_log_in, only: [:create]

  # GET /
  def feed
    set_title "Feed"
    #query = Post.connection.unprepared_statement { "((SELECT * FROM posts WHERE official) UNION DISTINCT (SELECT * FROM posts WHERE user_id = #{@current_user.id})) as posts" }
    #@posts = Post.includes(:user).from(query).order("created_at ASC")

    respond_to do |format|
      format.html {
        redirect_to '/signup' unless logged_in?
        @page = params[:page].to_i
        @page = 0 if @page < 0
        per_page = 30
        from = (@page * per_page)
        @posts = Post.includes(:user, :bans).all.order("id DESC").limit(per_page).offset(from)
        @posts.unshift(Post.includes(:user).where(official: true).order("id DESC").first) if @page == 0
        @posts = @posts.compact
        count = Post.count
        @num_of_pages = (count + per_page - 1) / per_page
      }
      # No json currently, I want draper for when I do that.
      format.rss { 
        @posts = Post.includes(:user, :bans).all.order("id DESC").limit(50)
        @feed_url = "main.rss"
        @feed_source = ""
        render action: "rss.html.erb", content_type: "application/rss", layout: false
      }
    end
  end

  # GET /feed/user/:user_id
  def user_feed
    set_title @user.display_name || @user.username
    respond_to do |format|
      format.html {
        @page = params[:page].to_i
        @page = 0 if @page < 0
        per_page = 30
        from = (@page * per_page)
        @posts = Post.where("user_id = ?", @user.id).includes(:user, :bans).order("id DESC").limit(per_page).offset(from)
        count = @user.posts.count
        @num_of_pages = (count + per_page - 1) / per_page
      }
      # No json currently, I want draper for when I do that.
      format.rss {
        @posts = Post.where("user_id = ?", @user.id).includes(:user, :bans).order("id DESC").limit(50)
        @feed_url = "user/#{@user.username}.rss"
        @feed_source = "user/#{@user.username}"
        render action: "rss.html.erb", content_type: "application/rss", layout: false
      }
    end
  end

  # GET /feed/official
  def official_feed
    set_title "Official Feed"
    respond_to do |format|
      format.html {
        @page = params[:page].to_i
        @page = 0 if @page < 0
        per_page = 30
        from = (@page * per_page)
        @posts = Post.where("official = ?", true).includes(:user, :bans).order("id DESC").limit(per_page).offset(from)
        count = Post.where("official = ?", true).count
        @num_of_pages = (count + per_page - 1) / per_page
      }
      # No json currently, I want draper for when I do that.
      format.rss { 
        @posts = Post.where("official = ?", true).includes(:user, :bans).order("id DESC").limit(50)
        @feed_url = "official.rss"
        @feed_source = "official"
        render action: "rss.html.erb", content_type: "application/rss", layout: false
      }
    end
  end

  # GET /feed/user/:user_id/:post_id
  def show
    respond_to do |format|
      format.html { set_title @post.user.display_name || @post.user.username }
      format.json { render :json => {id: @post.id, body: @post.body, user_id: @post.user.username, created_at: @post.created_at, updated_at: @post.updated_at} }
    end
  end

  # DELETE /feed/user/:user_id/:post_id
  def delete
    render plain: "You do not have permission to delete this post", status: 403 and return unless logged_in?
    post = Post.find(params["id"])
    render plain: "You do not have permission to delete this post", status: 403 and return if (post.user_id != @current_user.id or !@current_user.has_permission? "can_edit_own_posts") and !@current_user.has_permission? "can_edit_all_users_posts"
    post.destroy
    render plain: "OK"
  end

  # PATCH /feed/user/:user_id/:post_id
  def update
    render json: {errors: {'0' => 'You do not have permission to delete this post'}}, status: 403 and return unless logged_in?
    post = Post.find(params["id"])
    render json: {errors: {'0' => 'You do not have permission to delete this post'}}, status: 403 and return if (post.user_id != @current_user.id or !@current_user.has_permission? "can_edit_own_posts") and !@current_user.has_permission? "can_edit_all_users_posts"
    post.body = params["body"]
    if post.valid?
      post.save
      render json: {body: view_context.replace_urls(post.body)}
    else
      render json: {errors: post.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def ban
    render plain: "You do not have permission to delete this post", status: 403 and return unless logged_in?
    render plain: "You do not have permission to delete this post", status: 403 and return if !@current_user.has_permission? "can_ban_users"
    case params[:ban_duration]
    when "1w"
      duration = 1.week.from_now
    when "48h"
      duration = 48.hours.from_now
    when "perm"
      duration = nil
    when "other"
      duration = params[:ban_duration_datepicker]
    else
      render plain: "Ban duration is unset or invalid", status: 403 and return
    end
    @post.user.ban(params[:reason], duration, @post)
    respond_to do |format|
      format.html { redirect_to request.referrer || root_url, notice: "User was banned" }
      #render plain: "OK"
    end
  end

  # POST /new_post
  def create
    redirect_to '/signup' and return unless logged_in?
    flash[:warning] = "You don't have permission to create a post." and redirect_to request.referrer || root_url and return if !@current_user.has_permission? "can_create_post"
    if @current_user.has_permission? "can_create_official_posts"
      post_params = params.permit(:body, :official)
    else
      post_params = params.permit(:body)
    end
    post_params["user"] = @current_user
    post = Post.create(post_params)
    flash[:alert] = post.errors.full_messages.join("\n") unless post.valid?
    redirect_to request.referrer || root_url
  end

  private
    def set_post
      begin
        @post = Post.includes(:user, :bans).find_by(id: params[:post_id]) or not_found
      rescue ActionController::RoutingError
        render :template => 'shared/not_found', :status => 404
      end
    end

    def set_user
      begin
        @user = User.includes(:skills, :games, :posts).where("lower(username) = ?", params[:user_id].downcase).first or not_found
      rescue ActionController::RoutingError
        render :template => 'shared/not_found', :status => 404
      end
    end
end
