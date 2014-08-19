class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :body
      t.integer :infointerview_id
      t.integer :created_by
      t.integer :ambassador_id

      t.timestamps
    end
    
    add_index :comments, :infointerview_id, :unique => false
  end
end