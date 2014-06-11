class CreateQuizPublishers < ActiveRecord::Migration
  def change
    create_table :quiz_publishers do |t|
      t.string :name
      t.string :url

      t.timestamps
    end
  end
end
