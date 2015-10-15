class GroupController < ApplicationController
  before_action :required_log_in, only: [:create_post]
  before_action :set_group

  def show
    set_title @group.title
  end

  def create_post
    flash[:warning] = "You don't have permission to create a post." and redirect_to request.referrer || root_url and return if !@current_user.has_permission? "can_create_post"
    if @current_user.has_permission? "can_create_official_posts"
      post_params = params.permit(:body, :official)
    else
      post_params = params.permit(:body)
    end
    post_params["user"] = @current_user
    post_params["group"] = @group
    post = Post.create(post_params)
    flash[:alert] = post.errors.full_messages.join("\n") unless post.valid?
    redirect_to request.referrer || root_url
  end

  private
    def set_group
      begin
        @group = Group.includes(:users, :posts).find_by(slug: params[:id]) or not_found
      rescue ActionController::RoutingError 
        render :template => 'shared/not_found', :status => 404
      end
    end
end
