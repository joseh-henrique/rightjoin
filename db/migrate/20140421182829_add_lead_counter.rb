class AddLeadCounter < ActiveRecord::Migration
   def change
    add_column :infointerviews, :referred_by, :integer
    add_column :shares, :lead_counter, :integer, :default => 0
  end
end
