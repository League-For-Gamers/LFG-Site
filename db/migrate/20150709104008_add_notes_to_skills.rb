class AddNotesToSkills < ActiveRecord::Migration[4.2]
  def change
    add_column :skills, :note, :string
  end
end
