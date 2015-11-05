class GroupController < ApplicationController
  before_action :required_log_in, only: [:create_post, :join, :leave, :create, :new]
  before_action :set_group, except: [:new, :create]

  # GET /group/new
  def new
    flash[:warning] = "You don't have permission to create a group." and redirect_to request.referrer || root_url and return if !@current_user.has_permission? "can_create_group"
    @group = Group.new
    set_title "Create Group"
  end

  # POST /group/new
  def create
    flash[:warning] = "You don't have permission to create a group." and redirect_to request.referrer || root_url and return if !@current_user.has_permission? "can_create_group"
    @group = Group.new(create_params)
    membership = GroupMembership.new(user: @current_user, group: @group, role: :owner)
    respond_to do |format|
      if @group.valid?
        membership.save
        format.html { redirect_to "/group/#{@group.slug}", notice: 'Group was successfully created.' }
        format.json { render json: { status: 'ok' } }
      else
        format.html { render action: 'new' }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /group/:id
  def show
    set_title @group.title
  end

  # PATCH /group/:id
  def update
    flash[:warning] = "You don't have permission to update this group." and redirect_to request.referrer || root_url and return if !GroupMembership.has_permission? "can_create_post", @permissions
  end

  # POST /group/:id/new_post
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

  # GET /group/:id/join
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

  # GET /group/:id/leave
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
            @membership.role = @current_user.bans.where(group: @group).first.group_role
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

    def create_params
      params.require(:group).permit(:title, :description, :membership, :privacy, :comment_privacy)
    end
end
