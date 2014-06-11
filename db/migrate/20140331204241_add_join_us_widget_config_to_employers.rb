class AddJoinUsWidgetConfigToEmployers < ActiveRecord::Migration
  def change
    add_column :employers, :join_us_widget_params_map, :text
  end
end
