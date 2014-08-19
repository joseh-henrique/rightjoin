class RemoveBenefitsFromJobs < ActiveRecord::Migration
  def change
    remove_column :jobs, :benefit1
    remove_column :jobs, :benefit2
    remove_column :jobs, :benefit3
    remove_column :jobs, :benefit4
  end
end
