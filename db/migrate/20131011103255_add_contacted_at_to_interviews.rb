class AddContactedAtToInterviews < ActiveRecord::Migration
  def change
    add_column :interviews, :contacted_at, :datetime
  end
end
