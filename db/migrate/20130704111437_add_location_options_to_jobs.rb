class AddLocationOptionsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :allow_telecommuting, :boolean, :default => true
    add_column :jobs, :allow_relocation, :boolean, :default => true
  end
end
