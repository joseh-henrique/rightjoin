module EmployersHelper
  def box_shadow(params)
    "-webkit-box-shadow: #{params}; -moz-box-shadow: #{params}; box-shadow: #{params};"
  end
  
   def presentation_image_url(job)
      ret = nil
      photos = job.get_photos
      if photos.any?
        photo = photos.sample #Random photo
        ret = photo.image.standard.url(:secure => true)
      elsif !job.logo.nil?  #No photos, try to use company logo
        ret = job.logo.image.standard.url(:secure => true)
      else # Use RJ logo
        ret = full_image_url(Constants::REPRESENTATIVE_LOGO)
      end
      return ret
  end    
end