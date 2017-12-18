class AddHashedEmailToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :hashed_email, :string
  end
end
