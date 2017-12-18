class DropPermissionsTable < ActiveRecord::Migration[4.2]
  def change
    drop_table :permissions
    drop_table :permissions_roles
  end
end
