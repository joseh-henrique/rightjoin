class AddThemeToQuizzes < ActiveRecord::Migration
  def change
    add_column :quizzes, :theme, :string
  end
end
