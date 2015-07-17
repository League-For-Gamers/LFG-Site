class FeedController < ApplicationController
  before_action :set_post, only: [:show]

  # GET /
  def feed
    redirect_to '/signup' unless logged_in?
    set_title "Feed"
    #query = Post.connection.unprepared_statement { "((SELECT * FROM posts WHERE official) UNION DISTINCT (SELECT * FROM posts WHERE user_id = #{@current_user.id})) as posts" }
    #@posts = Post.includes(:user).from(query).order("created_at ASC")

    @page = params[:page].to_i
    @page = 0 if @page < 0
    per_page = 30
    from = (@page * per_page)
    @posts = Post.includes(:user).all.order("id DESC").limit(per_page).offset(from)
    @posts.unshift(Post.includes(:user).where(official: true).order("id DESC").first) if @page == 0
    count = Post.count
    @num_of_pages = (count + per_page - 1) / per_page
  end

  # GET /user/:user_id/:post_id
  def show
    respond_to do |format|
      format.html { set_title @post.user.display_name || @post.user.username }
      format.json { render :json => {id: @post.id, body: @post.body, user_id: @post.user.username, created_at: @post.created_at, updated_at: @post.updated_at} }
    end
  end

  # POST /user/post/delete
  def delete
    render plain: "You do not have permission to delete this post", status: 403 and return unless logged_in?
    post = Post.find(params["id"])
    render plain: "You do not have permission to delete this post", status: 403 and return if post.user_id != @current_user.id and !@current_user.has_permission? "can_edit_all_users_posts"
    post.delete
    render plain: "OK"
  end

  def update
    render json: {errors: {'0' => 'You do not have permission to delete this post'}}, status: 403 and return unless logged_in?
    post = Post.find(params["id"])
    render json: {errors: {'0' => 'You do not have permission to delete this post'}}, status: 403 and return if post.user_id != @current_user.id and !@current_user.has_permission? "can_edit_all_users_posts"
    post.body = params["body"]
    if post.valid?
      post.save
      render json: {body: view_context.replace_urls(post.body)}
    else
      render json: {errors: post.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # POST /new_post
  def create
    redirect_to '/signup' and return unless logged_in?
    if @current_user.has_permission? "can_create_official_posts"
      post_params = params.permit(:body, :official)
    else
      post_params = params.permit(:body)
    end
    post_params["user"] = @current_user
    Post.create(post_params)
    redirect_to request.referrer || root_url
  end

  private
      def set_post
        begin
          @post = Post.includes(:user).find_by(id: params[:post_id]) or not_found
        rescue ActionController::RoutingError 
          render :template => 'shared/not_found', :status => 404
        end
      end
end
