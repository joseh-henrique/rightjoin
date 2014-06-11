class CreatePositionTags < ActiveRecord::Migration
  def change
    create_table :position_tags do |t|
      t.string :name
      t.integer :priority, :default => 0

      t.timestamps
    end
    
    add_index :position_tags, :name, :unique => true
  end
end
