class AddEncryptionKeyToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :enc_key, :string
  end
end
