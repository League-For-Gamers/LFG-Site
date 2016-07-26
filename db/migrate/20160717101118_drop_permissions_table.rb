class DropPermissionsTable < ActiveRecord::Migration
  def change
    drop_table :permissions
    drop_table :permissions_roles
  end
end
