class AddJobIdToShares < ActiveRecord::Migration
   def change
    add_column :shares, :job_id, :integer
  end
end
