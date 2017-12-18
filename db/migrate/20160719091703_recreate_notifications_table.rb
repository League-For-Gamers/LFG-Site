class RecreateNotificationsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :notifications do |t|
      t.integer :variant, null: false
      t.hstore :data, default: {}, null: false
      t.boolean :read, default: false, null: false
      t.references :group, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true, null: false
      t.references :post, index: true, foreign_key: true

      t.timestamps null: false
    end
    add_index :notifications, [:user_id, :variant]
    add_index :notifications, [:user_id, :post_id]
    add_index :notifications, [:user_id, :post_id, :group_id]
  end
end
