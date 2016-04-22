class AddVersionToPrivateMessages < ActiveRecord::Migration
  def change
    add_column :private_messages, :version, :integer, default: 2
  end
end
