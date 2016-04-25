class AddSignatureToPost < ActiveRecord::Migration
  def change
    add_column :posts, :signed, :text
  end
end
