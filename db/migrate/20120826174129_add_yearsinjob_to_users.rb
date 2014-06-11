class AddYearsinjobToUsers < ActiveRecord::Migration
  def change
    add_column :users, :years_in_job, :integer, :default => 5
  end
end
