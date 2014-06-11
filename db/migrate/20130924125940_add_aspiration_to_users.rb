class AddAspirationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :aspiration, :integer
  end
end
