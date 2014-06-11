class CreateAmbassadors < ActiveRecord::Migration
  def change
    create_table :ambassadors do |t|
      t.string :provider
      t.string :uid
      t.integer :employer_id
      t.string :email
      t.string :title
      t.string :first_name
      t.string :last_name
      t.text :profile_links
      t.binary :avatar
      t.string :avatar_content_type
      t.integer :status, :default => 0

      t.timestamps
    end
    
    add_index :ambassadors, :employer_id, :unique => false
  end
end
