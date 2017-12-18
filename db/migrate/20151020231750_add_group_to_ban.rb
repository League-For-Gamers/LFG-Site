class AddGroupToBan < ActiveRecord::Migration[4.2]
  def change
    add_reference :bans, :group, index: true, foreign_key: true
    add_column :bans, :group_role, :text
    remove_column :group_memberships, :verified, :boolean
  end
end
