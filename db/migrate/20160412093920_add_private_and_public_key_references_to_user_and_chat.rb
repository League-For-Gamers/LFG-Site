class AddPrivateAndPublicKeyReferencesToUserAndChat < ActiveRecord::Migration
  def change
    add_column :users, :private_key_id, :integer, index: true, foreign_key: true
    add_column :users, :public_key_id, :integer, index: true, foreign_key: true
    add_column :users, :keypair_final, :boolean, default: false

    add_column :chats, :public_key_id, :integer, index: true, foreign_key: true
    add_column :chats, :version, :integer, default: 2
  end
end
