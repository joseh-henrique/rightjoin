class AddBenefitsListToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :benefits_list, :text, :default => ""
  end
end
