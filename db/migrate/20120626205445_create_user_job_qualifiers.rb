class CreateUserJobQualifiers < ActiveRecord::Migration
  def change
    create_table :user_job_qualifiers do |t|
      t.integer :job_qualifier_tag_id
      t.integer :user_id

      t.timestamps
    end
  end
end
