class MessagesController < ApplicationController
  before_action :set_chat, only: [:show, :older_messages, :new_messages, :create_message]
  before_action :required_log_in

  # For some unexplained reason, there is a bleed in the errors on flash messages.
  # To replicate, try sending these messages in quick succession to another user:
  # TEST1 # (posts "TEST1" message)
  # TEST1 # (duplicate error message shown, and the duplicate "TEST1" is not posted)
  # TEST2 # (duplicate error message shown, and "TEST2" is posted)
  #
  # I do not know why, but "touching" flash in this way changes the behavior to:
  # TEST1 # (posts "TEST1" message)
  # TEST1 # (duplicate error message shown, and the duplicate "TEST1" is not posted)
  # TEST2 # (posts "TEST1" message)
  before_action { flash }
  
  # GET /messages
  def index
    @chats = Chat.includes(:private_messages, :users)
                 .find_by_sql(["SELECT chats.*, chats_users.last_read FROM chats_users INNER JOIN chats ON chats_users.chat_id = chats.id WHERE chats_users.user_id = ? LIMIT 12", @current_user.id])
    @chats.sort! {|a,b| b.private_messages.first.created_at <=> a.private_messages.first.created_at} # Newest message takes precedent.
    @messages_count = @chats.count

    @notifications = @current_user.notifications.includes(:user, :group).all.limit(12)
    @notification_count = @notifications.count

    MarkNotificationsAsReadJob.perform_later(@notifications.to_a)
  end

  # POST /messages
  def index_ajax
    render plain: "Source parameter is missing", status: 403 and return if params[:source].blank?
    render plain: "Page parameter is missing", status: 403 and return if params[:page].blank?
    per_page = params[:per_page] || 12
    page = params[:page].to_i
    case params[:source]
    when "messages"
      @chats = Chat.includes(:private_messages, :users)
                   .find_by_sql(["SELECT chats.*, chats_users.last_read FROM chats_users INNER JOIN chats ON chats_users.chat_id = chats.id WHERE chats_users.user_id = ? LIMIT #{per_page} OFFSET #{(page)*per_page}", @current_user.id])
      @chats.sort! {|a,b| b.private_messages.first.created_at <=> a.private_messages.first.created_at} # Newest message takes precedent.
      render :raw_chat_cards, layout: false
    when "notifications"
      @notifications = @current_user.notifications.includes(:user, :group).all.limit(per_page).offset((page)*per_page)
      MarkNotificationsAsReadJob.perform_later(@notifications.to_a)
      render :raw_notifications, layout: false
    else
      render plain: "Invalid source parameter", status: 403 and return
    end
  end

  # GET /messages/new
  # def new
  # end

  # PUT /messages
  def create_chat
    # Eck... not proud of this
    flash[:warning] = "You do not have permission to send messages" and redirect_to root_url and return unless @current_user.has_permission? "can_send_private_messages"
    message_params = params.require(:private_message).permit(:body, {user: :id})
    @users = User.find(message_params["user"].map { |x| x[1]["id"] })
    @users << @current_user

    existing_chat = Chat.existing_chat?(@users)
    redirect_to "/messages/#{existing_chat.first.id}" and return unless existing_chat.empty?

    chat = Chat.new(users: @users)
    chat.save
    @message = PrivateMessage.new(chat: @chat, body: message_params["body"], user: @current_user)
    chat.private_messages << @message
    respond_to do |format|
      if @message.valid?
        chat.save
        MessageCountIncrementJob.perform_later(@message)
        format.html { redirect_to "/messages/#{chat.id}" }
        format.json { head :no_content }
      else
        @message.body = @message.decrypted_body # If we don't do this, the message field on the template is filled with garbage.
        chat.destroy
        @users = @users - [@current_user]
        format.html {
          flash[:alert] = @message.errors.full_messages.join("\n")
          render template: 'user/direct_message'
        }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /messages/:id
  def show
    @messages = @chat.private_messages.offset(0).limit(25)
    set_title "Chat between #{@chat.users.map(&:username).join(", ")}"
    MessageCountResolveJob.perform_later(@chat, @current_user, @chat.last_viewed(@current_user))
    @chat.update_timestamp(@current_user.id)
    @user_list = @chat.users.map(&:username).join(',')
    @chat_version = @chat.version
  end

  # GET /messages/:id/newer
  def new_messages
    # This is a stupid workaround BUT IT WORKS SO WHO CARES
    if !!params[:timestamp]
      @messages = @chat.private_messages.where("created_at > timestamp with time zone ? + interval '1 second'", params[:timestamp]).limit(25)
      MessageCountResolveJob.perform_later(@chat, @current_user, @chat.last_viewed(@current_user))
      @chat.update_timestamp(@current_user.id)
      render :raw_messages, layout: false
    else
      head :ok
    end
  end

  # GET /messages/:id/older
  def older_messages
    @messages = @chat.private_messages.where("created_at < ?", params[:timestamp]).limit(25)
    render :raw_messages, layout: false
  end

  # PUT /messages/:id
  def create_message
    flash[:warning] = "You do not have permission to send messages" and redirect_to root_url and return unless @current_user.has_permission? "can_send_private_messages"
    message_params = params.require(:private_message).permit(:body)
    message = PrivateMessage.new(body: message_params["body"], user: @current_user, chat: @chat)
    respond_to do |format|
      if message.valid?
        message.save
        MessageCountIncrementJob.perform_later(message)
        format.html { redirect_to "/messages/#{@chat.id}" }
        format.json { head :no_content }
      else
        # format.html { 
        #   flash[:alert] = message.errors.full_messages.join("\n")
        #   set_title "Chat between #{@chat.users.map(&:username).join(", ")}"
        #   @chat.update_timestamp(@current_user.id)
        #   @messages = @chat.private_messages.offset(0).limit(25)
        #   render action: 'show'
        # }
        format.json { render json: @current_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # TODO: Mark all as read button

  private
    def set_chat
      begin
        @chat = Chat.includes(:private_messages, :users).find_by(id: params[:id]) or not_found
        not_found unless @chat.users.include? @current_user
      rescue ActionController::RoutingError
        render :template => 'shared/not_found', :status => 404
      end
    end
end
