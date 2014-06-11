class AddBoardFieldsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :ad_url, :string
  end
end
