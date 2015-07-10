class AddBoxartToGame < ActiveRecord::Migration
  def change
    add_attachment :games, :boxart
  end
end
