class CreateCompanyRatings < ActiveRecord::Migration
  def change
    create_table :company_ratings do |t|
      t.integer :user_id
      t.string :company_name      
      t.integer :impact
      t.integer :worklife_balance
      t.integer :career_opportunitites
      t.integer :learning_opportunitites
      t.integer :workplace_perks
      t.integer :relaxed_culture
      t.integer :ace_colleagues

      t.timestamps
    end
    
    add_index :company_ratings, :user_id
  end
end
