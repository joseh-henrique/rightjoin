class AddReminderSentAtToAmbassadors < ActiveRecord::Migration
  def change
    add_column :ambassadors, :reminder_sent_at, :datetime
  end
end
