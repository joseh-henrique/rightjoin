class AddCountersToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :invites_counter, :integer, :default => 0
    add_column :jobs, :visits_counter, :integer, :default => 0
  end
end
