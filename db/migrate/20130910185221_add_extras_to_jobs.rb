class AddExtrasToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :add_extras, :boolean, :default => false
    add_column :jobs, :bleeding_edge_tech, :boolean, :default => false
    add_column :jobs, :take_time_you_need, :boolean, :default => false
    add_column :jobs, :two_steps_from_ceo, :boolean, :default => false
    add_column :jobs, :choose_hardware, :boolean, :default => false
    add_column :jobs, :learning_budget, :boolean, :default => false
    add_column :jobs, :awesome_office, :boolean, :default => false
    add_column :jobs, :stock_options, :boolean, :default => false
    add_column :jobs, :forty_hours_week, :boolean, :default => false
    add_column :jobs, :free_lunches, :boolean, :default => false
    add_column :jobs, :more_cool_stuff1, :string, :default => ""
    add_column :jobs, :more_cool_stuff2, :string, :default => ""
  end
end
