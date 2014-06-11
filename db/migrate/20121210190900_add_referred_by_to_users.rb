class AddReferredByToUsers < ActiveRecord::Migration
  def change
    add_column :users, :referred_by, :integer
    add_column :users, :last_referral_at, :datetime
  end
end
