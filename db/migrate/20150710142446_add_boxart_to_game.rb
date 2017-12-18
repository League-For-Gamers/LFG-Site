class AddBoxartToGame < ActiveRecord::Migration[4.2]
  def change
    add_attachment :games, :boxart
  end
end
