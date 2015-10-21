class AddGroupToBan < ActiveRecord::Migration
  def change
    add_reference :bans, :group, index: true, foreign_key: true
    add_column :bans, :group_role, :text
  end
end
