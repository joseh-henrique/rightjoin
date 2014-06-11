class AddQuestionsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :question1, :text
    add_column :jobs, :question_code1, :text
    add_column :jobs, :question_comment1, :text
    add_column :jobs, :question2, :text
    add_column :jobs, :question_code2, :text    
    add_column :jobs, :question_comment2, :text
    add_column :jobs, :question3, :text
    add_column :jobs, :question_code3, :text    
    add_column :jobs, :question_comment3, :text
    add_column :jobs, :question4, :text
    add_column :jobs, :question_code4, :text    
    add_column :jobs, :question_comment4, :text
    add_column :jobs, :question5, :text
    add_column :jobs, :question_code5, :text    
    add_column :jobs, :question_comment5, :text
  end
end
