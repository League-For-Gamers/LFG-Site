class UserController < ApplicationController
  before_action :set_user, only: [:show, :direct_message]
  skip_before_filter :set_current_user, only: [:my_account, :update, :direct_message]
  before_filter :set_current_user_with_includes, only: [:my_account, :update, :direct_message], if: :logged_in?
  before_action :required_log_in, only: [:my_account, :search, :direct_message, :logout]
  before_action :required_logged_out, only: [:forgot_password, :forgot_password_check, :signup, :login]

  # GET /login
  def login
    set_title "Login"
  end

  # POST /login
  def login_check
    user = User.where("lower(username) = ?", login_params[:username].downcase).first.try(:authenticate, login_params[:password])

    unless user.nil? or !user # Nil if there's no results, false if failed authentication
      login_user(user)
      redirect_to root_url
    else
      flash[:warning] = "Invalid username or password."
      set_title "Login"
      render "login"
    end
  end

  # GET /logout
  def logout
    flash[:info] = "Successfully logged out"
    logout_user and redirect_to "/signup" and return
  end

  # GET /user/forgot_password
  def forgot_password
  end

  # POST /user/forgot_password
  def forgot_password_check
    user = User.find_by(hashed_email: Digest::SHA384.hexdigest(params["email"].downcase + ENV['EMAIL_SALT']))
    unless user.blank?
      user.generate_verification_digest
      UserMailer.recovery_email(user).deliver_now
    end
  end

  # GET /user/forgot_password/:activation_id
  def reset_password
    # This could probably be done in a single query but ehhhhhh
    @user = User.find_by(verification_digest: params[:activation_id])
    @user = nil if @user.nil? or @user.verification_active < Time.now 
    render "reset_password_invalid" and return if @user.nil?
  end

  # POST /user/forgot_password/:activation_id
  def reset_password_check
    user = User.find_by(verification_digest: params[:activation_id])
    user = nil if user.nil? or user.verification_active < Time.now
    unless user.nil?
      digest = user.password_digest
      user.password = params["password"][0]
      user.password_confirmation = params["password"][0]
      user.skip_old_password = true
      user.verification_active = 1.hour.ago
      user.save
      flash[:info] = "Password has been changed. You can log in now."
      redirect_to '/signup' and return
    else
      flash[:info] = "The token you have provided is invalid or out of date."
      redirect_to '/signup' and return
    end
  end

  # GET /signup
  def signup
    @user = User.new 
    set_title("Signup")
  end

  # POST /signup
  def create
    @user = User.new(signup_params)

    respond_to do |format|
      if @user.save
        login_user(@user)
        format.html { redirect_to "/account", notice: 'User was successfully created.' }
        format.json { render action: 'show', status: :created, location: @user }
      else
        format.html { render action: 'signup' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /account
  def my_account
    set_title "Account Settings"
    @games = @current_user.games + [Game.new] # We always want there to be one empty field.
    @current_user.skills.build if @current_user.skills.empty?
  end

  # PATCH /account
  def update
    # Okay this is a wee bit dirty
    user_params = user_params()
    game_params = user_params["games"]
    user_params["display_name"] = nil if user_params["display_name"].blank?
    user_params.delete("games")
    user_params.delete("tags")
    user_params["tags_attributes"] = build_the_tag_attributes

    # Blank skills should be destroyed.
    unless user_params["skills_attributes"].blank?
      user_params["skills_attributes"].each_with_index do |x, i|
        if x[1]["category"].empty?
          user_params["skills_attributes"]["#{i}"]["_destroy"] = '1'
        end
      end
    end

    @current_user.assign_attributes(user_params)
    # Fill out the game list of the user
    unless game_params.nil?
      games = game_params.map { |x| x[1]["name"].strip }.uniq(&:downcase).reject(&:empty?) # I would work on the hash directly but empty strings cause havoc
      @current_user.games = games.map { |x| Game.where("lower(name) = ?", x.downcase).first || Game.create(name: x) }
    end
    respond_to do |format|
      if @current_user.errors.size < 1 and @current_user.valid?
        @current_user.save
        format.html { redirect_to '/account', notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        set_title "Account Settings"
        @games = @current_user.games + [Game.new]
        format.html { render action: 'my_account' }
        format.json { render json: @current_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /user/:id
  def show
    set_title @user.display_name || @user.username
  end

  # GET /search
  def search
    set_title "Search"
    search_params = params.permit(:query, :filter, :page)

    unless search_params["query"].blank? and search_params["filter"].blank?
      @query = search_params["query"]
      @filter = search_params["filter"]
      @query_string = search_params.map{|x|"#{x[0]}=#{x[1]}"}.join("&")

      unless @query.blank?
        search = PgSearch.multisearch(@query).with_pg_search_rank

        tag_search = search.map {|x| [x.searchable_id, x.rank] if x.searchable_type == "Tag"}.compact
        tag_list = Tag.includes(user: [:skills]).where(id: tag_search.map{|x|x[0]}).map{|x|x.user}
        user_search = search.map {|x| [x.searchable_id, x.rank] if x.searchable_type == "User"}.compact
        user_list = User.includes(:skills).where(id: user_search.map{|x|x[0]})

        user_list.each_with_index do |u,i|
          user_search[i][0] = u
        end

        tag_list.each_with_index do |t,i|
          tag_search[i][0] = t
        end

        @results = (user_search + tag_search).sort {|x,y| x[1] <=> y[1]}.map{|x|x[0]}.uniq
      else
        @results = User.includes(:skills).order("display_name DESC, username DESC")
      end

      
      unless @filter.blank?
        # Oh jesus.
        @results = @results.map {|x| x if x.skills.map(&:category).include? @filter }.compact
        # The higher the confidence, the higher the ranking.
        @results.sort! { |x,y| y.skills.to_a.select {|x| x.category == @filter }[0].confidence <=> x.skills.to_a.select {|x| x.category == @filter }[0].confidence }
      end

      per_page = 10
      count = @results.size
      @page_num = search_params["page"].to_i || 0
      offset = @page_num * per_page
      @num_of_pages = count / per_page
      start_num = 0 + offset
      @results = @results[start_num...start_num + per_page]
    end
  end

  # POST /ajax/user/hide
  def profile_hide
    render status: 403, plain: "Must be logged in" and return if @current_user.nil?
    p = params.permit(:section)
    @current_user.hidden[p["section"]] = !(@current_user.hidden[p["section"]] == 'true')
    @current_user.save
    render plain: "OK"
  end

  # GET /user/:user_id/message
  def direct_message
    flash[:warning] = "You do not have permission to send messages" and redirect_to root_url and return unless @current_user.has_permission? "can_send_private_messages"
    # oh jesus this query.
    existing_chat = Chat.find_by_sql ["SELECT DISTINCT chats.* FROM chats, chats_users WHERE chats.id IN ( SELECT chat_id FROM chats_users WHERE chats_users.user_id = ? INTERSECT ALL SELECT chat_id FROM chats_users WHERE chats_users.user_id = ? EXCEPT SELECT chat_id FROM chats_users WHERE chats_users.user_id != ? AND chats_users.user_id != ?)", @current_user.id, @user.id, @current_user.id, @user.id]
    redirect_to "/messages/#{existing_chat.first.id}" and return unless existing_chat.empty?
    flash[:info] = "You can't send a message to yourself." and redirect_to root_url and return if @user == @current_user
    @users = [@user]
    @message = PrivateMessage.new()
  end

  private
    def set_current_user_with_includes
      @current_user = User.includes(:skills, :games, :tags).find session[:user]
    end

    def set_user
      begin
        @user = User.includes(:skills, :games, :posts).where("lower(username) = ?", params[:id].downcase).first or not_found
      rescue ActionController::RoutingError
        render :template => 'shared/not_found', :status => 404
      end
    end

    def login_params
      params.permit(:username, :password)
    end

    def signup_params
      params.require(:user).permit(:username, :password, :email, :email_confirm)
    end

    def user_params
      params.require(:user).permit(:old_password, :password, :password_confirmation, :bio, :display_name, :avatar, :tags, :skill_notes,
                                   {games: :name}, 
                                   social: [:portfolio, :website, :link_facebook, :link_googleplus, :link_instagram, :link_linkedin, :link_twitter, :link_youtube],
                                   skills_attributes: [:id, :category, :confidence, :note])
    end

    def build_the_tag_attributes
      tags = user_params["tags"].to_s.split(/[,\n\r]/).map(&:strip).select(&:present?)

      tags.map    { |t| Tag.find_or_create_by(name: t, user: @current_user) }
          .select { |t| t.invalid? }
          .each   { |t| t.errors.messages.each { |e| @current_user.errors.add("Tag", e[1][0]) } }

      @current_user.tags.each_with_index.reduce({}) do |t, i|
        tag, index = i[0], i[1]
        t.merge!("#{i}" => { 'id'       => tag.id,
                             'name'     => tag.name,
                             '_destroy' => tags.include?(tag.name) ? nil : '1' } )
      end
    end
end
