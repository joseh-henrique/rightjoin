class AddReminderPeriodToEmployers < ActiveRecord::Migration
  def change
    add_column :employers, :reminder_period, :integer, :default => 0
  end
end
