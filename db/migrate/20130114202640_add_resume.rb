class AddResume < ActiveRecord::Migration
  def change
    add_column :users, :resume, :text
    add_column :interviews, :resume, :text
    add_column :jobs, :resume_mandatory, :boolean, :default => true
  end
end
