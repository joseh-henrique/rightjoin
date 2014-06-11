class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.integer :employer_id
      t.integer :position_id
      t.text :description
      t.integer :location_id
      t.string :company_name
      t.string :company_url      
      t.integer :status, :default => 0
      t.timestamps
    end
    
    add_index :jobs, :employer_id
  end
end
