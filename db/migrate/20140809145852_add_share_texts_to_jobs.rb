class AddShareTextsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :share_title, :text
    add_column :jobs, :share_description, :text
    add_column :jobs, :share_short_description, :text
  end
end
