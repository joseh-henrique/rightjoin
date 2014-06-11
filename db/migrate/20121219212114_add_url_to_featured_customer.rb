class AddUrlToFeaturedCustomer < ActiveRecord::Migration
  def change
    add_column :featured_customers, :url, :string
  end
end
