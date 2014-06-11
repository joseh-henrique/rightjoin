class CreateQuizChoices < ActiveRecord::Migration
  def change
    create_table :quiz_choices do |t|
      t.integer :quiz_question_id
      t.integer :position, :default => 0
      t.string :choice
      t.integer :weight, :default => 0
      t.integer :counter, :default => 0

      t.timestamps
    end
    
    add_index :quiz_choices, :quiz_question_id
  end
end
