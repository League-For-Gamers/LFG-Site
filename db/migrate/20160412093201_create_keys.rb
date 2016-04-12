class CreateKeys < ActiveRecord::Migration
  def change
    create_table :keys do |t|
      t.integer :key_type
      t.references :user, index: true, foreign_key: true
      t.references :group, index: true, foreign_key: true
      t.integer :parent_id, index: true, foreign_key: true
      t.string :body

      t.timestamps null: false
    end
  end
end
