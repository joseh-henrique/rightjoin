class AddImageSetToPhotos < ActiveRecord::Migration
  def change
    add_column :photos, :image_set, :string
    add_index :photos, :image_set, :unique => false
  end
end
