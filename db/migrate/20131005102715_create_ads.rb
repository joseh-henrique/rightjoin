class CreateAds < ActiveRecord::Migration
  def change
    create_table :ads do |t|
      t.integer :job_id
      t.integer :board_id

      t.timestamps
    end
    
    add_index :ads, :job_id, :unique => false
    add_index :ads, :board_id, :unique => false
  end
end
