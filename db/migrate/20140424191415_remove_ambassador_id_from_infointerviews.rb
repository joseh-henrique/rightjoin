class RemoveAmbassadorIdFromInfointerviews < ActiveRecord::Migration
  def change
    remove_column :infointerviews, :ambassador_id
  end
end
