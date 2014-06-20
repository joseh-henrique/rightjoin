class AddJoinUsWidgetConfigToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :join_us_widget_params_map, :text
  end
end
