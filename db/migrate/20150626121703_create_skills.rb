class CreateSkills < ActiveRecord::Migration[4.2]
  def change
    create_table :skills do |t|
      t.integer :category # Enum. Type is a reserved name.
      t.references :user, index: true, foreign_key: true
      t.integer :confidence

      t.timestamps null: false
    end
  end
end
