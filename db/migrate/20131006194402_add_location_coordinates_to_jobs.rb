class AddLocationCoordinatesToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :northmost, :decimal, :precision => 15, :scale => 12
    add_column :jobs, :southmost, :decimal, :precision => 15, :scale => 12
    add_column :jobs, :westmost, :decimal, :precision => 15, :scale => 12
    add_column :jobs, :eastmost, :decimal, :precision => 15, :scale => 12    
    
    add_index :jobs, :northmost
    add_index :jobs, :southmost
    add_index :jobs, :westmost
    add_index :jobs, :eastmost
  end
end
