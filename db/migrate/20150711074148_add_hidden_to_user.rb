class AddHiddenToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :hidden, :hstore, default: {}, null: false
  end
end
