class DropMessages < ActiveRecord::Migration
  def up
    drop_table :messages
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
