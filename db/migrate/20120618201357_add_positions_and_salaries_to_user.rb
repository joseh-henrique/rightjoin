class AddPositionsAndSalariesToUser < ActiveRecord::Migration
  def change
    add_column :users, :current_position_id, :integer
    add_column :users, :wanted_position_id, :integer
    add_column :users, :wanted_salary, :integer, :default => 0
  end
end
