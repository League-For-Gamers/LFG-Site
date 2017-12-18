class AddExtraDataToPost < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :extra_data, :hstore, default: {}
  end
end
