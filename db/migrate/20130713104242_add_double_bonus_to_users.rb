class AddDoubleBonusToUsers < ActiveRecord::Migration
  def change
    add_column :users, :double_bonus, :boolean, :default => false
  end
end
