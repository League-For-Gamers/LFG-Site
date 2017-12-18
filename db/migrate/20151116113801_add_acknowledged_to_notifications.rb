class AddAcknowledgedToNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :notifications, :acknowledged, :boolean, default: false
  end
end
