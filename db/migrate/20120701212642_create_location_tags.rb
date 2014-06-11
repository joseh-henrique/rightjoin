class CreateLocationTags < ActiveRecord::Migration
  def change
    create_table :location_tags do |t|
      t.string :name
      t.integer :priority, :default => 0

      t.timestamps
    end
    
    add_index :location_tags, :name, :unique => true    
  end
end
