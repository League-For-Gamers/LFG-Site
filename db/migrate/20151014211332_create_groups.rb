class CreateGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :groups do |t|
      t.string :title, limit: 100, unique: true, null: false
      t.string :slug, limit: 100, unique: true, null: false, index: true # URL Slug, eg: "league_for_gamers"
      t.string :description, limit: 1000
      t.integer :privacy, default: 0, null: false
      t.integer :comment_privacy, default: 0, null: false
      t.integer :membership, default: 0, null: false
      t.attachment :banner

      t.timestamps null: false
    end

    create_table :group_memberships do |t|
      t.references :group, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.integer :role, null: false
      t.boolean :verified, default: false

      t.timestamps null: false
    end

    add_reference :posts, :group, index: true, foreign_key: true
  end
end
