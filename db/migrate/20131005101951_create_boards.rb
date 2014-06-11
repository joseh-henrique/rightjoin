class CreateBoards < ActiveRecord::Migration
  def change
    create_table :boards do |t|
      t.string :name
      t.string :title
      t.text :description
      t.string :tag
      t.integer :order

      t.timestamps
    end
  end
end
