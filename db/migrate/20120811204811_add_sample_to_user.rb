class AddSampleToUser < ActiveRecord::Migration
  def change
    add_column :users, :sample, :boolean
  end
end
