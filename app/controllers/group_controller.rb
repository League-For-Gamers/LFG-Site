class GroupController < ApplicationController
  before_action :required_log_in, except: [:show, :index, :index_ajax, :search]
  before_action :set_group, except: [:new, :create, :index, :index_ajax, :search]

  # GET /group
  def index
    set_title "Groups"
    @user_groups = @current_user.groups.limit(12) if !!@current_user
    @groups = Group.where.not(privacy: Group.privacies[:private_group]).limit(12)
  end

  # POST /group
  def index_ajax
    render plain: "Source parameter is missing", status: 403 and return if params[:source].blank?
    render plain: "Page parameter is missing", status: 403 and return if params[:page].blank?
    per_page = params[:per_page] || 12
    page = params[:page].to_i
    case params[:source]
    when "all"
      @groups = Group.where.not(privacy: Group.privacies[:private_group]).limit(per_page).offset((page)*per_page)
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

  # POST /group/:id/delete
  def delete
    flash[:warning] = "You don't have permission to delete this group." and redirect_to request.referrer || root_url and return unless universal_permission_check("can_delete_group")
    flash[:warning] = "The group needs to have no members before you can delete it." and redirect_to request.referrer || root_url and return if (@group.group_memberships.size > 1 and !@current_user.has_permission? "can_delete_group")
    flash[:warning] = "The confirmation title does not match the group title." and redirect_to request.referrer || root_url and return if params[:confirmation].downcase != @group.title.downcase
    @group.destroy
    redirect_to "/group", notice: "Group was successfully been deleted"
  end

  # GET /group/:id
  def show
    @stickied_posts = @group.posts.where(official: true)
    @group_posts = @group.posts.limit(30)
    set_title @group.title
  end

  # PATCH /group/:id
  def update
    flash[:warning] = "You don't have permission to update this group." and redirect_to request.referrer || root_url and return unless universal_permission_check("can_update_group")
    @group.assign_attributes(update_params)
    respond_to do |format|
      if @group.valid?
        @group.save
        format.html { redirect_to request.referrer || "/group/#{@group.slug}", notice: 'Group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { redirect_to request.referrer || "/group/#{@group.slug}", notice: "Error updating group: #{@group.errors.full_messages.join("\n")}" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /group/:id/members
  def members
    flash[:warning] = "You don't have permission to view this list." and redirect_to request.referrer || root_url and return unless universal_permission_check("can_view_group_members")
    set_title "Members of #{@group.title}"
    @members = {}
    keys = GroupMembership.roles.keys
    keys.delete("unverified") unless universal_permission_check "can_edit_group_member_roles"
    keys.each do |k|
      g = @group.group_memberships.includes(:user).where(role: GroupMembership.roles[k]).limit(10).order("created_at DESC")
      @members[k] = g.map(&:user) unless g.empty?
    end
  end

  # POST /group/:id/members
  def members_ajax
    render plain: "You don't have permission to view this list.", status: 403 and return unless universal_permission_check("can_view_group_members")
    render plain: "Source parameter is missing", status: 403 and return if params[:source].blank?
    render plain: "Page parameter is missing", status: 403 and return if params[:page].blank?
    per_page = params[:per_page] || 10
    page = params[:page].to_i
    keys = GroupMembership.roles.keys
    keys.delete("unverified") unless universal_permission_check("can_edit_group_member_roles")
    render plain: "Invalid source parameter", status: 403 and return unless keys.include? params[:source]
    @members = @group.group_memberships.includes(:user).where(role: GroupMembership.roles[params[:source]]).limit(per_page).offset((page)*per_page).order("created_at ASC")
    render :raw_user_cards, layout: false and return
  end

  # GET /group/:id/members/:user_id
  def membership
    flash[:warning] = "You don't have permission to edit this membership." and redirect_to request.referrer || root_url and return unless universal_permission_check("can_edit_group_member_roles")
    begin
      @user = User.includes(:skills, :games, :posts).where("lower(username) = ?", params[:user_id].downcase).first or not_found
      @user_membership = GroupMembership.find_by(user: @user, group: @group) or not_found
      bans = Ban.where(user: @user_membership.user, group: @user_membership.group).order("created_at DESC")
      @user_bans = {}
      bans.each do |ban|
        time_ago = ActionView::Base.new.time_ago_in_words(ban.created_at) + " ago"
        @user_bans[time_ago] = [] unless @user_bans.has_key? time_ago
        @user_bans[time_ago] << ban
      end
      set_title "Edit @#{@user.username}"
    rescue ActionController::RoutingError 
      render template: 'shared/not_found', status: 404 and return
    end
  end

  # PATCH /group/:id/members/:user_id
  def update_membership
    flash[:warning] = "You don't have permission to edit this membership." and redirect_to request.referrer || root_url and return unless universal_permission_check("can_edit_group_member_roles")
    begin
      @user = User.includes(:skills, :games, :posts).where("lower(username) = ?", params[:user_id].downcase).first or not_found
      @user_membership = GroupMembership.find_by(user: @user, group: @group) or not_found
    rescue ActionController::RoutingError 
      render template: 'shared/not_found', status: 404 and return
    end
    flash[:warning] = "Goal parameter missing" and redirect_to request.referrer || root_url and return if params[:goal].blank?
    case params[:goal]
    when "role"
      @user_membership.assign_attributes(membership_update_params)
    when "promote"
      flash[:warning] = "User is already the owner" and redirect_to request.referrer || root_url and return if @user_membership.role == "owner"
      owner = GroupMembership.find_by(group: @group, role: GroupMembership.roles[:owner])
      owner.role = :administrator
      @user_membership.role = :owner
    when "approve"
      @user_membership.role = :member
      @user.create_notification("group_accepted", @group)
    else
      flash[:warning] = "Invalid goal parameter" and redirect_to request.referrer || root_url and return
    end
    if @user_membership.valid? and (!owner or owner.valid?)
      @user_membership.save
      owner.save if params[:goal] == "promote"
      flash[:info] = "User has been successfully updated!"
    else
      # Currently can't create a situation where this is called, I think.
      # :nocov:
      flash[:warning] = "An error has occurred when updating this user: #{@user_membership.errors.full_messages.join("\n")}"
      # :nocov:
    end
    redirect_to request.referrer || root_url
  end

  # POST /group/:id/members/:user_id/ban
  def ban
    render plain: "You do not have permission to ban this user", status: 403 and return unless universal_permission_check "can_ban_users"
    begin
      @user = User.includes(:skills, :games, :posts).where("lower(username) = ?", params[:user_id].downcase).first or not_found
      @user_membership = GroupMembership.find_by(user: @user, group: @group) or not_found
    rescue ActionController::RoutingError 
      render template: 'shared/not_found', status: 404 and return
    end

    case params[:duration]
    when "unban"
      @user_membership.unban(params[:reason], @current_user)
      flash[:info] = "User has been successfully unbanned"
      redirect_to request.referrer || root_url
      return
    when "one_day"
      duration = 1.day.from_now
    when "three_days"
      duration = 3.days.from_now
    when "one_week"
      duration = 1.week.from_now
    when "one_month"
      duration = 1.month.from_now
    when "perm"
      duration = nil
    else
      flash[:warning] = "Invalid duration parameter" and redirect_to request.referrer || root_url and return
    end

    begin
      if @user_membership.ban(params[:reason], duration, @current_user)
        flash[:info] = "User has been successfully banned"
      else
        # I have no idea how to make this happen in a test.
        # :nocov:
        flash[:warning] = "Could not ban user for unknown reason"
      end
    rescue Exception => e
      flash[:warning] = e.message
      # :nocov:
    end
    redirect_to request.referrer || root_url
  end

  # POST /group/:id/new_post
  def create_post
    flash[:warning] = "You don't have permission to create a post." and redirect_to request.referrer || root_url and return unless universal_permission_check("can_create_post")
    if universal_permission_check("can_create_official_posts")
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

  # GET /group/search
  def search
    set_title "Search"
    search_params = params.permit(:query, :sort, :page)
    search_params["query"] = params["source"] if !!params["source"]
    unless search_params["query"].blank? and search_params["sort"].blank?
      @group_query = search_params["query"]
      @sort = search_params["sort"]
      unless @group_query.blank?
        @groups = Group.search_by_title(@group_query).with_pg_search_rank
        @groups = @groups.map { |x| x unless x.privacy == "private_group" }.compact # Remove private groups.

        # I'm not sure how sort is going to be used, or if it really will but I want it to be at least open to it
        if @sort.blank?
          @groups = @groups.sort { |x,y| y.pg_search_rank <=> x.pg_search_rank }
        end

        per_page = 12
        @count = @groups.size
        @page_num = search_params["page"].to_i || 0
        offset = @page_num * per_page
        @num_of_pages = @count / per_page
        start_num = 0 + offset
        @groups = @groups[start_num...start_num + per_page]
        render :raw_cards, layout: false and return if !!params["raw"]
      end
    end
  end

  # GET /group/:group_id/posts/:post_id
  def show_post
    begin
      @post = Post.includes(:user, :bans).find_by(id: params[:post_id]) or not_found
      not_found if @post.group != @group
    rescue ActionController::RoutingError 
      render :template => 'shared/not_found', :status => 404
    end

    respond_to do |format|
      format.html { set_title @group.title }
      format.json { render :json => {id: @post.id, body: @post.body, user_id: @post.user.username, created_at: @post.created_at, updated_at: @post.updated_at} }
    end
  end

  # TODO: Moderation log, group invite

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
        render template: 'shared/not_found', status: 404
      end
    end

    def create_params
      params.require(:group).permit(:title, :description, :membership, :privacy, :comment_privacy)
    end

    def update_params
      if @current_user.role == Role.find(1)
        params.require(:group).permit(:title, :description, :membership, :privacy, :post_control, :banner, :official)
      else
        params.require(:group).permit(:description, :membership, :privacy, :post_control, :banner)
      end
    end

    def membership_update_params
      params.require(:group_membership).permit(:role)
    end

    def universal_permission_check(permission, options = {})
      permissions = options[:permissions] || @permissions
      user = options[:user] || @current_user
      !!user and (GroupMembership.has_permission? permission, permissions or user.has_permission? permission)
    end
end
