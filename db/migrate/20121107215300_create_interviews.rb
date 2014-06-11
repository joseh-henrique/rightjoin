class CreateInterviews < ActiveRecord::Migration
  def change
    create_table :interviews do |t|
      t.integer :employer_id
      t.integer :user_id
      t.integer :job_id
      
      t.text :question1
      t.text :question_code1      
      t.text :question_comment1
      t.string :answer_meta1
      t.text :answer1
      
      t.text :question2
      t.text :question_code2   
      t.text :question_comment2
      t.string :answer_meta2
      t.text :answer2
      
      t.text :question3
      t.text :question_code3
      t.text :question_comment3
      t.string :answer_meta3
      t.text :answer3
      
      t.text :question4
      t.text :question_code4
      t.text :question_comment4
      t.string :answer_meta4
      t.text :answer4
      
      t.text :question5
      t.text :question_code5
      t.text :question_comment5
      t.string :answer_meta5
      t.text :answer5

      t.datetime :answered
      t.integer :status, :default => 0
      t.date :starts_on
      t.timestamps
    end

    add_index :interviews, :user_id
    add_index :interviews, :employer_id
    add_index :interviews, :job_id
  end
end
