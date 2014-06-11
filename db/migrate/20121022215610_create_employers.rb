class CreateEmployers < ActiveRecord::Migration
  def change
    create_table :employers do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :li_url
      t.string :company_name
      t.string :company_url
      t.boolean :sample
    
      t.string :password_digest
      t.string :remember_token

      t.integer :status, :default => 0
      
      t.timestamps
    end
    
    add_index :employers, :email, :unique => true
    add_index :employers, :remember_token
  end
end
