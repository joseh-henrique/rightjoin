class AddBoardTitleToQuizPublishers < ActiveRecord::Migration
  def change
    add_column :quiz_publishers, :board_title, :string
  end
end
