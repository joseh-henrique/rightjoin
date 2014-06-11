class AddDisplayOrderToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :display_order, :integer, :default => 0
    add_index :jobs, :display_order, :unique => false
  end
end
