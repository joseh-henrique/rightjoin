class RemoveDefaultForYearsOnJob < ActiveRecord::Migration
  def up
		change_column_default(:users, :years_in_job, nil)
		# add_column :users, :years_in_job, :integer, :default => 5
		# drop_column :users, :years_in_job  
  end

  def down
  end
end
