class FixRemindersTable < ActiveRecord::Migration
  def change
    rename_column :reminders, :user_type, :recipient_type
    rename_column :reminders, :interview_id, :linked_object_id   
  end
end
