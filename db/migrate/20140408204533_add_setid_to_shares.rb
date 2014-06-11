class AddSetidToShares < ActiveRecord::Migration
  def change
    change_column :shares, :click_counter, :integer, default: 0
    add_column :shares, :setid, :string
    add_index :shares, :setid, :unique => true
  end
end
