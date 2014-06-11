class CreateSkillTags < ActiveRecord::Migration
  def change
    create_table :skill_tags do |t|
      t.string :name
      t.integer :priority, :default => 0

      t.timestamps
    end
    
    add_index :skill_tags, :name, :unique => true
  end
end
