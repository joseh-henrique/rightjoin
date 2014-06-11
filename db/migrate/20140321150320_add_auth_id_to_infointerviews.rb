class AddAuthIdToInfointerviews < ActiveRecord::Migration
  def change
    add_column :infointerviews, :auth_id, :integer
  end
end
