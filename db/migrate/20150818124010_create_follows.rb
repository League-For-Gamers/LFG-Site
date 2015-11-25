class CreateFollows < ActiveRecord::Migration
  def change
    create_table :follows do |t|
      t.references :user, index: true, foreign_key: true
      t.integer :following_id, index: true

      t.timestamps null: false 
    end
    add_foreign_key "follows", "users", column: "following_id"
  end
end

