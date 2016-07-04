class CreateTwitterVerifications < ActiveRecord::Migration
  def change
    create_table :twitter_verifications do |t|
      t.string :screen_name
      t.string :token
      t.string :secret
      t.integer :user_id
      t.timestamps
    end
  end
end
