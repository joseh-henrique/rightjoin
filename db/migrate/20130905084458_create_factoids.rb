class CreateFactoids < ActiveRecord::Migration
  def change
    create_table :factoids do |t|
      t.string :content
      t.boolean :for_candidate
      t.boolean :for_employer

      t.timestamps
    end
  end
end
