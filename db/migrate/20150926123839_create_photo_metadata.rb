class CreatePhotoMetadata < ActiveRecord::Migration
  def change
    create_table :photo_metadata do |t|
      t.string :hash

      t.timestamps null: false
    end
    add_attachment :photo_metadata, :photo
  end
end
