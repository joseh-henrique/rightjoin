class AddFreeTextToUsers < ActiveRecord::Migration
  def change
    add_column :users, :free_text, :string
  end
end
