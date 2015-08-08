class MessageCountResolveJob < ActiveJob::Base
  queue_as :low_priority

  def perform(chat, user, timestamp)
    count = chat.new_messages_since(timestamp, user)
    user.unread_count -= count
    user.save
  end
end
