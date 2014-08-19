class AddFullDescriptionToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :full_description, :text
  end
end
