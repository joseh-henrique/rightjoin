class CreateAuths < ActiveRecord::Migration
  def change
    create_table :auths do |t|
      t.string :provider
      t.string :uid
      t.string :first_name
      t.string :last_name
      t.string :title
      t.text :profile_links_map
      t.string :email
      t.binary :avatar
      t.string :avatar_content_type

      t.timestamps
    end
    
    add_index :auths, :email, :unique => false
    add_index :auths, [:provider, :uid], :unique => true
  end
end
