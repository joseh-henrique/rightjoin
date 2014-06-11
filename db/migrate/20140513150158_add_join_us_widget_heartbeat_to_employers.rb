class AddJoinUsWidgetHeartbeatToEmployers < ActiveRecord::Migration
  def change
    add_column :employers, :join_us_widget_heartbeat, :datetime
  end
end
