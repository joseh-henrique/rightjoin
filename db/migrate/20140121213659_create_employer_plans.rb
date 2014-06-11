class CreateEmployerPlans < ActiveRecord::Migration
  def change
    create_table :employer_plans do |t|
      t.integer :tier
      t.integer :monthly_price
      t.integer :employer_id

      t.timestamps
    end
    
    add_index :employer_plans, :employer_id, :unique => false
  end
end
