class AddLogoAndCompanyUrlToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :logo_image_id, :integer
    add_column :jobs, :company_url, :string
  end
end
