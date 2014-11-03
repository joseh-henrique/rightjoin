class AddVouchedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :vouched, :boolean, :default => false
  end
end
