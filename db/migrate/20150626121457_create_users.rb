class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :username
      t.string :password_digest
      t.string :display_name
      t.string :quote
      t.text :bio

      t.timestamps null: false
    end
  end
end
