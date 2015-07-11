class AddHiddenToUser < ActiveRecord::Migration
  def change
    add_column :users, :hidden, :hstore, default: {}, null: false
  end
end
