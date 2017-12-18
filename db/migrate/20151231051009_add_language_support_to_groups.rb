class AddLanguageSupportToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :language, :integer, default: 0
  end
end
