class CreateInfointerviews < ActiveRecord::Migration
  def change
    create_table :infointerviews do |t|
      t.string :email
      t.string :first_name
      t.string :last_name
      t.integer :job_id
      t.integer :user_id
      t.integer :ambassador_id
      t.text :profiles
      t.text :free_text
      t.integer :status, :default => 0

      t.timestamps
    end
    
    add_index :infointerviews, :job_id, :unique => false
    add_index :infointerviews, :ambassador_id, :unique => false
  end
end
