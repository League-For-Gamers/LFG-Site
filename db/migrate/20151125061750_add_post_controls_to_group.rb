class AddPostControlsToGroup < ActiveRecord::Migration
  def change
    add_column :groups, :post_control, :integer, default: 0
  end
end
