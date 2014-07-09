class AddVideoUrlToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :video_url, :string
  end
end
