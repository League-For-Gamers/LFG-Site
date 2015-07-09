class AddNotesToSkills < ActiveRecord::Migration
  def change
    add_column :skills, :note, :string
  end
end
