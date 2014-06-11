class AddTechStackToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :tech_stack_list, :text, :default => ""
  end
end
