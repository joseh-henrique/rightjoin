class GetRidOfPreScreening < ActiveRecord::Migration
  def change
    remove_column :jobs, :question1
    remove_column :jobs, :question_code1  
    remove_column :jobs, :question_comment1
      
    remove_column :jobs, :question2
    remove_column :jobs, :question_code2 
    remove_column :jobs, :question_comment2

    remove_column :jobs, :question3
    remove_column :jobs, :question_code3
    remove_column :jobs, :question_comment3

    remove_column :jobs, :question4
    remove_column :jobs, :question_code4
    remove_column :jobs, :question_comment4

    remove_column :jobs, :question5
    remove_column :jobs, :question_code5
    remove_column :jobs, :question_comment5
    
    remove_column :jobs, :resume_mandatory
    
    
    remove_column :interviews, :question1
    remove_column :interviews, :question_code1  
    remove_column :interviews, :question_comment1
    remove_column :interviews, :answer_meta1
    remove_column :interviews, :answer1
      
    remove_column :interviews, :question2
    remove_column :interviews, :question_code2 
    remove_column :interviews, :question_comment2
    remove_column :interviews, :answer_meta2
    remove_column :interviews, :answer2
      
    remove_column :interviews, :question3
    remove_column :interviews, :question_code3
    remove_column :interviews, :question_comment3
    remove_column :interviews, :answer_meta3
    remove_column :interviews, :answer3
      
    remove_column :interviews, :question4
    remove_column :interviews, :question_code4
    remove_column :interviews, :question_comment4
    remove_column :interviews, :answer_meta4
    remove_column :interviews, :answer4
      
    remove_column :interviews, :question5
    remove_column :interviews, :question_code5
    remove_column :interviews, :question_comment5
    remove_column :interviews, :answer_meta5
    remove_column :interviews, :answer5
  end
end
