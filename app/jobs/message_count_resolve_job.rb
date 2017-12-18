class MessageCountResolveJob < ApplicationJob
  queue_as :low_priority

  def perform(chat, user, timestamp)
    count = chat.new_messages_since(timestamp, user)
    user.unread_count -= count
    user.unread_count = 0 if user.unread_count <= 0
    user.save
  end
end 
