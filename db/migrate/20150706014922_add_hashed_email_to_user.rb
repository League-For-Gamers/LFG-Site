class AddHashedEmailToUser < ActiveRecord::Migration
  def change
    add_column :users, :hashed_email, :string
  end
end
