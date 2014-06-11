class CleanupModel < ActiveRecord::Migration
  def change
    remove_column :employers, :company_url
    remove_column :jobs, :company_url
    remove_column :jobs, :add_extras      
    remove_column :jobs, :bleeding_edge_tech      
    remove_column :jobs, :take_time_you_need      
    remove_column :jobs, :two_steps_from_ceo      
    remove_column :jobs, :choose_hardware     
    remove_column :jobs, :learning_budget     
    remove_column :jobs, :awesome_office      
    remove_column :jobs, :stock_options     
    remove_column :jobs, :forty_hours_week      
    remove_column :jobs, :free_lunches      
    remove_column :jobs, :more_cool_stuff1      
    remove_column :jobs, :more_cool_stuff2
    remove_column :interviews, :answered    
    remove_column :interviews, :resume
  end
end
