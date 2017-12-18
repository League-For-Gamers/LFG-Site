class AddUniqueIndexToGames < ActiveRecord::Migration[4.2]
  def change
    add_index :games, :name, :unique => true
  end
end
