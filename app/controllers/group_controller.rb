class GroupController < ApplicationController
  before_action :required_log_in, only: [:create_post]
  before_action :set_group

  def show
    set_title @group.title
  end

  def create_post
    flash[:warning] = "You don't have permission to create a post." and redirect_to request.referrer || root_url and return if !@membership.has_permission? "can_create_post", @permissions
    if @membership.has_permission? "can_create_official_posts", @permissions
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
        @membership = @group.group_memberships.find_by(user: @current_user) if !!@current_user
        # Group unban mechanism
        if !!@current_user and !!@membership and @membership.role == "banned"
          if @current_user.bans.where(group: @group).first.end_date != nil and @current_user.bans.where(group: @group).first.end_date < Time.now 
            @membership.role = @current_user.bans.where(group: @group).first.role
            @membership.save
          else
            @group_ban = @current_user.bans.where(group: @group).first
          end
        end
        @permissions = @membership.get_permission if !!@membership
      rescue ActionController::RoutingError 
        render :template => 'shared/not_found', :status => 404
      end
    end
end
