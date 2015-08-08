class AddLastReadToChatsUsers < ActiveRecord::Migration
  def change
    add_column :chats_users, :last_read, :datetime
    add_column :users, :unread_count, :integer, default: 0
    reversible do |dir|
      dir.up do
        execute 'ALTER TABLE chats_users ALTER COLUMN last_read SET DEFAULT now()'
      end
    end
  end
end
