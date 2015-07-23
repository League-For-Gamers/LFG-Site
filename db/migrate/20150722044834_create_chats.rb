class CreateChats < ActiveRecord::Migration
  def change
    create_table :chats do |t|
      t.string :key

      t.timestamps null: false
    end

    create_join_table :chats, :users do |t|
      # t.index [:user_id, :chat_id]
      t.index [:user_id, :chat_id], unique: true
    end
  end
end
