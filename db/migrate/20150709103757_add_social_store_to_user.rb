class AddSocialStoreToUser < ActiveRecord::Migration
  def change
    add_column :users, :social, :hstore, default: {}, null: false
    add_column :users, :skill_notes, :text
    add_column :users, :skill_status, :integer
  end
end
