class CreateShares < ActiveRecord::Migration
  def change
    create_table :shares do |t|
      t.integer :ambassador_id
      t.string :network
      t.integer :click_counter

      t.timestamps
    end
    
    add_index :shares, :ambassador_id, :unique => false
    add_index :shares, :network, :unique => false
  end
end
