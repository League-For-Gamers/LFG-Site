class AddParentToPost < ActiveRecord::Migration
  def change
    add_column :posts, :parent_id, :integer, default: nil, null: true, index: true, foreign_key: true
    add_column :posts, :children_count, :integer, default: 0, null: false, index: true
  end
end
