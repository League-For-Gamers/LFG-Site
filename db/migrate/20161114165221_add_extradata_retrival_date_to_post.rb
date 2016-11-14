class AddExtradataRetrivalDateToPost < ActiveRecord::Migration
  def change
    add_column :posts, :extra_data_date, :timestamp
  end
end
