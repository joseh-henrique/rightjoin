class AddContactInfo < ActiveRecord::Migration
  def change
    add_column :users, :contact_info, :string
    add_column :interviews, :contact_info, :string
  end
end
