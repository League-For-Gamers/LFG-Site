class AddMembershipCounterToGroup < ActiveRecord::Migration
  def change
    add_column :groups, :membership_count, :integer
    add_column :groups, :official, :boolean, default: false
  end
end
