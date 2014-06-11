class AddLocationCoordinates < ActiveRecord::Migration
  def change
    add_column :users, :northmost, :decimal, :precision => 15, :scale => 12
    add_column :users, :southmost, :decimal, :precision => 15, :scale => 12
    add_column :users, :westmost, :decimal, :precision => 15, :scale => 12
    add_column :users, :eastmost, :decimal, :precision => 15, :scale => 12    
    
    add_index :users, :northmost
    add_index :users, :southmost
    add_index :users, :westmost
    add_index :users, :eastmost
    
    add_column :location_tags, :latitude, :decimal, :precision => 15, :scale => 12
    add_column :location_tags, :longitude, :decimal, :precision => 15, :scale => 12        
  end
end
