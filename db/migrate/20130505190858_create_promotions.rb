class CreatePromotions < ActiveRecord::Migration
  def change
    create_table :promotions do |t|
      t.integer :quiz_publisher_id
      t.integer :skill_tag_id
      t.string :ad

      t.timestamps
    end
    
    add_index :promotions, :quiz_publisher_id
    add_index :promotions, :skill_tag_id
  end
end
