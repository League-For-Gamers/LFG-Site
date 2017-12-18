class DropRoleUserJoinTable < ActiveRecord::Migration[4.2]
  def change
    drop_join_table :roles, :users
  end
end
