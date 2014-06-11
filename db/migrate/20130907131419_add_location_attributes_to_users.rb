class AddLocationAttributesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :can_relocate, :boolean
    add_column :users, :can_telecommute, :boolean
  end
end
