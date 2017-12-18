class ActivateHstore < ActiveRecord::Migration[4.2]
  def change
    enable_extension 'hstore'
  end
end
