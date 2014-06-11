class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string :sender_auth_token
      t.string :sender_auth_provider
      t.integer :user_id
      t.text :body
      t.integer :status, :default => 0

      t.timestamps
    end
    
    add_index :messages, :user_id
  end
end
