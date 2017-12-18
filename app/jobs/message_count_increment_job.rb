class MessageCountIncrementJob < ApplicationJob
  queue_as :default

  def perform(message)
    message.chat.users.each do |user|
      user.increment!(:unread_count) unless user == message.user
    end
  end
end
