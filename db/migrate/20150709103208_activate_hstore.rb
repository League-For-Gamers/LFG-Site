class ActivateHstore < ActiveRecord::Migration
  def change
    enable_extension 'hstore'
  end
end
