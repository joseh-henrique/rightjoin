class ImageUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave
 
 
  version :standard do
     eager
     # The following commented-out line transforms the image as it is enters  Cloudinary. However it should  not be needed, since the image is resized in the browser right before  upload to Cloudinary.
          # cloudinary_transformation :transformation => [  {:width =>  Photo::MAX_WIDTH , :height => Photo::MAX_HEIGHT , :crop => :limit}] # :crop really means "resize"
      
      process :custom_crop        
   end  

 def custom_crop     
    # The model crop_x, crop_y etc etc values are  taken with respect to the photo after upload, with max dimensions max-width/max-height  
    return :x => model.crop_x, :y => model.crop_y, 
       :width => model.crop_w , :height => model.crop_h, 
       :crop => :crop      
  end
 

end
