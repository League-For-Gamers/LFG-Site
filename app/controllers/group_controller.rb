class GroupController < ApplicationController
  before_action :required_log_in, except: [:show, :index, :index_ajax]
  before_action :set_group, except: [:new, :create, :index, :index_ajax]

  # GET /group
  def index
    @groups = Group.all.limit(12)
    @user_groups = @current_user.groups.limit(12) if !!@current_user
  end

  # POST /group
  def index_ajax
    render plain: "Source parameter is missing", status: 403 and return if params[:source].blank?
    render plain: "Page parameter is missing", status: 403 and return if params[:page].blank?
    per_page = params[:per_page] || 12
    page = params[:page].to_i
    case params[:source]
    when "all"
      @groups = Group.all.limit(per_page).offset((page)*per_page)
      render :raw_cards, layout: false and return
    when "user"
      render plain: "You must be logged in", status: 403 and return if !@current_user
      @groups = @current_user.groups.limit(per_page).offset((page)*per_page)
      render :raw_cards, layout: false and return
    else
      render plain: "Invalid source parameter", status: 403 and return
    end
  end

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
    @membership = GroupMembership.new(user: @current_user, group: @group, role: :owner)
    respond_to do |format|
      if @group.valid? and @membership.valid?
        @membership.save
        format.html { redirect_to "/group/#{@group.slug}", notice: 'Group was successfully created.' }
        format.json { head :no_content }
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
    flash[:warning] = "You don't have permission to update this group." and redirect_to request.referrer || root_url and return if (!GroupMembership.has_permission? "can_update_group", @permissions and !@current_user.has_permission? "can_update_group")
    @group.assign_attributes(update_params)
    respond_to do |format|
      if @group.valid?
        @group.save
        format.html { redirect_to "/group/#{@group.slug}", notice: 'Group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'show', notice: "Error updating group: #{@group.errors.full_messages.join("\n")}" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /group/:id/new_post
  def create_post
    flash[:warning] = "You don't have permission to create a post." and redirect_to request.referrer || root_url and return if (!GroupMembership.has_permission? "can_create_post", @permissions and !@current_user.has_permission? "can_update_group")
    if GroupMembership.has_permission? "can_create_official_posts", @permissions or @current_user.has_permission? "can_create_official_posts"
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
    flash[:warning] = "You cannot join groups while globally banned" and redirect_to request.referrer || root_url and return if !@current_user.has_permission? "can_join_group"
    flash[:warning] = "This group is invite only. Please message the owner of the group to request access" and redirect_to request.referrer || root_url and return if @group.membership == "invite_only"
    flash[:warning] = "You are already part of this group" and redirect_to request.referrer || root_url and return if !!@membership
    message = "You have successfully joined the group"
    g = GroupMembership.new(user: @current_user, group: @group)
    if @group.membership == "owner_verified"
      g.role = :unverified
      message = "You have requested to join this group. You will be notified when you are accepted"
    else
      g.role = :member
    end
    # I couldn't find a way to make a request genuinely invalid in tests so I have to force it...
    if Rails.env.test? and params[:invalid]
      g.role = nil
    end
    if g.valid?
      g.save
    else
      message = "There was an error joining the group: #{g.errors.full_messages.join("\n")}"
    end
    flash[:info] = message
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

    def update_params
      if @current_user.role == Role.find(1)
        params.require(:group).permit(:title,:description, :membership, :privacy, :banner, :official)
      else
        params.require(:group).permit(:description, :membership, :privacy, :banner)
      end
    end
end
