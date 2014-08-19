class LowerIndexForNameInPositionTags < ActiveRecord::Migration
  def up
    remove_index :position_tags, :name
    execute "CREATE UNIQUE INDEX index_position_tags_on_lowercase_name ON position_tags USING btree (lower(name));"
  end

  def down
    execute "DROP INDEX index_position_tags_on_lowercase_name;"
    add_index :position_tags, :name, :unique => true
  end
end
