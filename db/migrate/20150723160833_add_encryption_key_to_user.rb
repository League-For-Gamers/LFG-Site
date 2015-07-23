class AddEncryptionKeyToUser < ActiveRecord::Migration
  def change
    add_column :users, :enc_key, :string
  end
end
