class CreateGamesJoinTable < ActiveRecord::Migration[4.2]
  def change
    create_join_table :games, :users do |t|
      # t.index [:user_id, :game_id]
      t.index [:user_id, :game_id], unique: true
    end
  end
end
