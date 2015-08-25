class Chat < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :private_messages, -> { order 'id DESC'}, dependent: :destroy

  validate :validates_chat_user_uniqueness, on: :create

  before_validation do
    self.key = self.key || SecureRandom.hex(64)
  end

  def new_messages(user)
    new_messages_count(user) > 0
  end

  def update_timestamp(user_id)
    q = ActiveRecord::Base.connection.unprepared_statement { "UPDATE chats_users SET last_read = Now() WHERE user_id = #{user_id} AND chat_id = #{self.id}" }
    ActiveRecord::Base.connection.execute(q)
  end

  def last_viewed(user)
    q = ActiveRecord::Base.connection.unprepared_statement { "SELECT chats_users.last_read FROM chats_users WHERE chats_users.chat_id = #{self.id} AND chats_users.user_id = #{user.id} LIMIT 1" }
    ActiveRecord::Base.connection.execute(q).values[0][0]
  end

  def new_messages_count(user)
    # This can do with some optimization. A CTE can do this in one query.
    self.private_messages.where('created_at > ?', self.last_viewed(user)).where('user_id != ?', user.id).count
  end

  def new_messages_since(timestamp, user)
    self.private_messages.where('created_at > ?', timestamp).where('user_id != ?', user.id).count
  end

  def self.existing_chat?(user1, user2)
    Chat.find_by_sql ["SELECT DISTINCT chats.* FROM chats, chats_users WHERE chats.id IN ( SELECT chat_id FROM chats_users WHERE chats_users.user_id = ? INTERSECT ALL SELECT chat_id FROM chats_users WHERE chats_users.user_id = ? EXCEPT SELECT chat_id FROM chats_users WHERE chats_users.user_id != ? AND chats_users.user_id != ?)", user1.id, user2.id, user1.id, user2.id]
  end

  private
    # Currently doesn't scale to multi-user. Needs to be fixed.
    def validates_chat_user_uniqueness
      return if Chat.existing_chat?(self.users.first, self.users.last).empty?
      errors.add(:chat, "already exists") 
    end
end
