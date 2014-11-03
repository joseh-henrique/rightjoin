class AddUpdateCandidateToInfointerviews < ActiveRecord::Migration
  def change
    add_column :infointerviews, :update_candidate_after_ping, :boolean, :default => false
  end
end
