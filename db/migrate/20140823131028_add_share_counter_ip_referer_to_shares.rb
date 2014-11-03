class AddShareCounterIpRefererToShares < ActiveRecord::Migration
  def change
    add_column :shares, :share_counter, :integer, :default => 0
    add_column :shares, :ip, :string
    add_column :shares, :referer, :string
    remove_column :shares, :setid
  end
  add_index :shares, :job_id, :unique => false
end
