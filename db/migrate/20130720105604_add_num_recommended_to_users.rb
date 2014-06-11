class AddNumRecommendedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :num_recommended, :integer, :default => 0
  end
end
