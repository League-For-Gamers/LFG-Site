class CreatePermissionJoinTable < ActiveRecord::Migration[4.2]
  def change
    create_join_table :permissions, :roles do |t|
      # t.index [:permission_id, :role_id]
      t.index [:role_id, :permission_id], unique: true
    end
    create_join_table :roles, :users do |t|
      # t.index [:user_id, :role_id]
      t.index [:role_id, :user_id], unique: true
    end
  end
end
