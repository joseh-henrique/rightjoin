class AddAuthIdToAmbassadors < ActiveRecord::Migration
  def change
    add_column :ambassadors, :auth_id, :integer
  end
end
