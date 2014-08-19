class AddEnablePingToEmployers < ActiveRecord::Migration
  def change
    add_column :employers, :enable_ping, :boolean, :default => true
  end
end
