class CreateJobQualifierTags < ActiveRecord::Migration
  def change
    create_table :job_qualifier_tags do |t|
      t.string :name
      t.integer :priority, :default => 0

      t.timestamps
    end
    
    add_index :job_qualifier_tags, :name, :unique => true
  end
end
