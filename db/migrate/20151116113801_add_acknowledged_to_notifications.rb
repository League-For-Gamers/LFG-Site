class AddAcknowledgedToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :acknowledged, :boolean, default: false
  end
end
