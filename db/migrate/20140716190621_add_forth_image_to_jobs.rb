class AddForthImageToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :image_4_id, :integer
  end
end
