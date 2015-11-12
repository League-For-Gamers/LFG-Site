class AddDurationAndBannerToBans < ActiveRecord::Migration
  def change
    add_column :bans, :duration_string, :string
    add_column :bans, :banner_id, :integer
  end
end
