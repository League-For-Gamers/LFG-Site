class AddVerificationDigestToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :verification_digest, :string
    add_column :users, :verification_active, :datetime
  end
end
