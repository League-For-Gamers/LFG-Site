class AddEmailAndRemoveQuoteFromUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :email, :binary
    add_column :users, :email_iv, :binary
    remove_column :users, :quote, :string
  end
end
