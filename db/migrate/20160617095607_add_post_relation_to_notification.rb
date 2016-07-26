class AddPostRelationToNotification < ActiveRecord::Migration
  def change
    add_column :notifications, :post_id, :integer, default: nil, null: true, index: true, foreign_key: true
  end
end
