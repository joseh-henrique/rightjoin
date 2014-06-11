class CreateQuizResults < ActiveRecord::Migration
  def change
    create_table :quiz_results do |t|
      t.integer :quiz_publisher_id
      t.integer :quiz_choice_id
      t.integer :result_set

      t.timestamps
    end
    
    add_index :quiz_results, :quiz_publisher_id
    add_index :quiz_results, :quiz_choice_id
    add_index :quiz_results, :result_set
  end
end
