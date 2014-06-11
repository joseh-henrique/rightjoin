class RemoveVisitsCounterFromJobs < ActiveRecord::Migration
  def change
    remove_column :jobs, :visits_counter
  end
end
