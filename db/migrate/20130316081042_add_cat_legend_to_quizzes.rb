class AddCatLegendToQuizzes < ActiveRecord::Migration
  def change
    add_column :quizzes, :cat1_legend, :string
    add_column :quizzes, :cat2_legend, :string
    add_column :quizzes, :cat3_legend, :string
  end
end
