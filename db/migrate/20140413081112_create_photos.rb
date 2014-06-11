class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.string :title
      t.string :image
      t.integer :bytes
       t.integer :crop_x
       t.integer :crop_y
       t.integer :crop_w
       t.integer :crop_h
      t.timestamps
    end
  end
end
