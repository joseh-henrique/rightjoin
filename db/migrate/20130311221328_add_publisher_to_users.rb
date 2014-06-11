class AddPublisherToUsers < ActiveRecord::Migration
  def change
    add_column :users, :publisher_id, :integer
    add_index :users, :publisher_id
  end
end
