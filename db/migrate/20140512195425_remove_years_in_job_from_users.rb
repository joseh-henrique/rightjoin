class RemoveYearsInJobFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :years_in_job
  end
end
