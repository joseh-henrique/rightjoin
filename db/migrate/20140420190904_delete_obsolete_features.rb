class DeleteObsoleteFeatures < ActiveRecord::Migration
  def up
    remove_column :users, :referred_by
    remove_column :users, :last_referral_at
    remove_column :users, :publisher_id    
    
    drop_table :promotions
    drop_table :quiz_choices
    drop_table :quiz_publishers
    drop_table :quiz_questions
    drop_table :quiz_results
    drop_table :quizzes
    drop_table :featured_customers
    drop_table :factoids    
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
