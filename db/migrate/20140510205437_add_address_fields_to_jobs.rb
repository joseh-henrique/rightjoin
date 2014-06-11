class AddAddressFieldsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :address, :string
    add_column :jobs, :address_lat, :decimal, :precision => 15, :scale => 12
    add_column :jobs, :address_lng, :decimal, :precision => 15, :scale => 12 
  end
end
