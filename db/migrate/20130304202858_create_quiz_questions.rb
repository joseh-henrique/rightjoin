class CreateQuizQuestions < ActiveRecord::Migration
  def change
    create_table :quiz_questions do |t|
      t.integer :quiz_id
      t.integer :position, :default => 0
      t.string :question

      t.timestamps
    end
    
    add_index :quiz_questions, :quiz_id
  end
end
