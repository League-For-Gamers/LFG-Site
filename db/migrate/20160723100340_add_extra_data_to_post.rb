class AddExtraDataToPost < ActiveRecord::Migration
  def change
    add_column :posts, :extra_data, :hstore, default: {}
  end
end
