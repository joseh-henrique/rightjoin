class CreateReminders < ActiveRecord::Migration
  def change
    create_table :reminders do |t|
      t.string :user_type
      t.integer :user_id
      t.integer :employer_id
      t.integer :interview_id
      t.string :reminder_type

      t.timestamps
    end
  end
end
