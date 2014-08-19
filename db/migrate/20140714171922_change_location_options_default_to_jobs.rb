class ChangeLocationOptionsDefaultToJobs < ActiveRecord::Migration
  def up
    change_column :jobs, :allow_relocation, :boolean, :default => false
    change_column :jobs, :allow_telecommuting, :boolean, :default => false
  end
  
  def down
    change_column :jobs, :allow_relocation, :boolean, :default => true
    change_column :jobs, :allow_telecommuting, :boolean, :default => true    
  end
end
