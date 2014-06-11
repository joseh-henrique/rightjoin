class AddFamilyIdToPositionTags < ActiveRecord::Migration
  def change
    add_column :position_tags, :family_id, :integer
  end
end
