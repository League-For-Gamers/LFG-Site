class AddVerificationDigestToUser < ActiveRecord::Migration
  def change
    add_column :users, :verification_digest, :string
    add_column :users, :verification_active, :datetime
  end
end
