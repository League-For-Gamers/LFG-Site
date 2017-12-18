class AddAvatarToUser < ActiveRecord::Migration[4.2]
  def change
    add_attachment :users, :avatar
  end
end
