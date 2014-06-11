class AddImagesToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :image_1_id, :integer
    add_column :jobs, :image_2_id, :integer
    add_column :jobs, :image_3_id, :integer
  end
end
