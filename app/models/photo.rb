class Photo < ActiveRecord::Base
 
  MAX_CROP_WIDTH = 360  # If you change this, also change value in  photos.css.sccc
  MAX_CROP_HEIGHT = 270 
  ASPECT_RATIO_FOR_CROP_WINDOW = MAX_CROP_WIDTH.to_f / MAX_CROP_HEIGHT.to_f

  MAX_WIDTH = 1000 #This is the max width of the photo after upload. During upload, it will be resized in the browser before upload as needed to make this happen.   
  MAX_HEIGHT = 600 #Likewise for height
  
  # crop_x, crop_y, crop_w, crop_h  values are  taken with respect to the photo after upload, with max dimensions max-width/max-height
  # bytes means "size in bytes"
  attr_accessible :title, :bytes, :image, :image_cache, :crop_x, :crop_y, :crop_w, :crop_h, :image_set
  mount_uploader :image, ImageUploader
  
  has_many :jobs1, :class_name => "Job", :dependent => :nullify, :foreign_key => 'image_1_id'
  has_many :jobs2, :class_name => "Job", :dependent => :nullify, :foreign_key => 'image_2_id'  
  has_many :jobs3, :class_name => "Job", :dependent => :nullify, :foreign_key => 'image_3_id'  
  has_many :jobs_with_logo, :class_name => "Job", :dependent => :nullify, :foreign_key => 'logo_image_id'
  
  def self.get_group_name(obj, suffix)
    return "#{obj.class.name}_#{obj.id}_#{suffix}".downcase
  end
end


