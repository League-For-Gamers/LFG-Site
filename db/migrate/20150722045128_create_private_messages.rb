class CreatePrivateMessages < ActiveRecord::Migration
  def change
    create_table :private_messages do |t|
      t.references :user, index: true, foreign_key: true
      t.references :chat, index: true, foreign_key: true
      t.binary :body
      t.binary :iv

      t.timestamps null: false
    end
  end
end
