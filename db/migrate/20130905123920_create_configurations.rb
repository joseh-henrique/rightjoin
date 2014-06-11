class CreateConfigurations < ActiveRecord::Migration
  def change
    create_table :fyi_configurations do |t|
      t.string :key
      t.string :value

      t.timestamps
    end
  end
end
