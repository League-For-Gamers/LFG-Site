class AddLanguageSupportToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :language, :integer, default: 0
  end
end
