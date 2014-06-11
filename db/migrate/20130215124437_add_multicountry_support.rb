class AddMulticountrySupport < ActiveRecord::Migration
  def change
    add_column :users, :locale, :string, :default => "en"
    add_index :users, :locale
    add_column :jobs, :locale, :string, :default => "en"
    add_index :jobs, :locale    
  end
end
