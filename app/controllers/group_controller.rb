class GroupController < ApplicationController
  before_action :required_log_in, only: [:create_post, :join, :leave]
  before_action :set_group

  def show
    set_title @group.title
  end

  def create_post
    flash[:warning] = "You don't have permission to create a post." and redirect_to request.referrer || root_url and return if !GroupMembership.has_permission? "can_create_post", @permissions
    if GroupMembership.has_permission? "can_create_official_posts", @permissions
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

  def join
    flash[:warning] = "This group is invite only. Please message the owner of the group to request access" and redirect_to request.referrer || root_url and return if @group.membership == "invite_only"
    flash[:warning] = "You are already part of this group" and redirect_to request.referrer || root_url and return if !!@membership
    g = GroupMembership.new(user: @current_user, group: @group)
    if @group.membership == "owner_verified"
      g.role = :unverified
      flash[:info] = "You have requested to join this group. You will be notified when you are accepted"
    else
      g.role = :member
      flash[:info] = "You have successfully joined the group"
    end
    g.save
    redirect_to request.referrer || root_url
  end

  def leave
    flash[:warning] = "You are not a part of this group" and redirect_to request.referrer || root_url and return if !@membership
    # Tricky people try to leave and rejoin to get unbanned. BUT I'M BETTER THAN YOUUUU
    flash[:warning] = "You cannot leave a group while banned" and redirect_to request.referrer || root_url and return if @membership.role == "banned"
    flash[:warning] = "You cannot leave the group if you are the owner. Appoint someone else, first!"  and redirect_to request.referrer || root_url and return if @membership.role == "owner"
    @membership.destroy
    flash[:info] = "You have successfully left the group"
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
        @permissions = GroupMembership.get_permission(@membership, @group) if !!@current_user
        not_found if @group.privacy == "private_group" and !@membership # Private groups are private.
      rescue ActionController::RoutingError 
        render :template => 'shared/not_found', :status => 404
      end
    end
end
