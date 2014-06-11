class CreateUserSkills < ActiveRecord::Migration
  def change
    create_table :user_skills do |t|
      t.integer :skill_tag_id
      t.integer :user_id
      t.integer :seniority

      t.timestamps
    end
  end
end
