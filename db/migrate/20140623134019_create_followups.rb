class CreateFollowups < ActiveRecord::Migration
  def change
    create_table :followups do |t|
      t.integer :status, :default => 0
      t.integer :ambassador_id
      t.integer :infointerview_id

      t.timestamps
    end
    
    add_index :followups, :ambassador_id, :unique => false
  end
end
