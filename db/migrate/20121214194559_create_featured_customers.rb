class CreateFeaturedCustomers < ActiveRecord::Migration
  def change
    create_table :featured_customers do |t|
      t.string :company_name

      t.timestamps
    end
  end
end
