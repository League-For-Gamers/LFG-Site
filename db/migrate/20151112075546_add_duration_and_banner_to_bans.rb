class AddDurationAndBannerToBans < ActiveRecord::Migration[4.2]
  def change
    add_column :bans, :duration_string, :string
    add_column :bans, :banner_id, :integer
  end
end
