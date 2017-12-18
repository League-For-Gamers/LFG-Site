class AddPostRelationToNotification < ActiveRecord::Migration[4.2]
  def change
    add_column :notifications, :post_id, :integer, default: nil, null: true, index: true, foreign_key: true
  end
end
