class AddBenefitsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :benefit1, :string
    add_column :jobs, :benefit2, :string
    add_column :jobs, :benefit3, :string
    add_column :jobs, :benefit4, :string
  end
end
