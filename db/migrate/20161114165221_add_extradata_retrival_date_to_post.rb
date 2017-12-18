class AddExtradataRetrivalDateToPost < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :extra_data_date, :timestamp
  end
end
