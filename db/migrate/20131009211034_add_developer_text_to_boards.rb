class AddDeveloperTextToBoards < ActiveRecord::Migration
  def change
    add_column :boards, :developer_text, :string
  end
end
