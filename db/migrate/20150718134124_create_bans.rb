class CreateBans < ActiveRecord::Migration[4.2]
  def change
    create_table :bans do |t|
      t.references :user, index: true, foreign_key: true
      t.references :post, index: true, foreign_key: true
      t.references :role, index: true # Original user role to restore on unban.
      t.string :reason
      t.date :end_date

      t.timestamps null: false
    end
  end
end
