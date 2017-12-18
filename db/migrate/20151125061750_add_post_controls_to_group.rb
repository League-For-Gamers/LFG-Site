class AddPostControlsToGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :post_control, :integer, default: 0
  end
end
