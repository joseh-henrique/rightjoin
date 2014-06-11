class CreateQuizzes < ActiveRecord::Migration
  def change
    create_table :quizzes do |t|
      t.string :name
      t.string :title
      t.string :cat1_title
      t.text :cat1_description
      t.integer :cat1_counter, :default => 0
      t.string :cat2_title
      t.text :cat2_description
      t.integer :cat2_counter, :default => 0
      t.string :cat3_title
      t.text :cat3_description
      t.integer :cat3_counter, :default => 0

      t.timestamps
    end
  end
end
