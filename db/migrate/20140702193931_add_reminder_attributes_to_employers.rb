class AddReminderAttributesToEmployers < ActiveRecord::Migration
  def change
    add_column :employers, :reminder_subject, :string
    add_column :employers, :reminder_body, :text
  end
end
