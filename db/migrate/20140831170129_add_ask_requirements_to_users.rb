class AddAskRequirementsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :ask_requirements, :boolean, :default => false
  end
end
