class AddPromotionsCompoundIndex < ActiveRecord::Migration
  def change
    add_index :promotions, [:quiz_publisher_id, :skill_tag_id], :unique => true
  end
end
