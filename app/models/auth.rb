class Auth < ActiveRecord::Base
  serialize :profile_links_map, JSON
  
  validates :provider, :presence => true
  validates :uid, :presence => true
  validates :email, :allow_blank => true, :format=> { :with=> Constants::VALID_EMAIL_REGEX }, :length => { :maximum => 255 }
  before_save { |a| a.email = a.email.downcase unless a.email.blank? }
  
  has_many :infointerviews, :dependent => :destroy
  has_many :ambassadors, :dependent => :destroy
  
  def self.create_from_oauth!(data)
     provider = data["provider"].downcase
     uid = data["uid"]
     
     auth = Auth.find_by_provider_and_uid(provider, uid)
     auth ||= Auth.new
     
     auth.provider = provider
     auth.uid = uid
     
     auth.email = data.info["email"]
  
    # reset to refresh links
    auth.profile_links_map = {}
    
     if provider == Constants::TWITTER.downcase
         auth.add_profile_link_from_oauth(data, Constants::TWITTER)
     elsif provider == Constants::GITHUB.downcase
         auth.add_profile_link_from_oauth(data, Constants::GITHUB)
         auth.add_profile_link_from_oauth(data, "Blog")
     elsif provider.start_with?(Constants::GOOGLE.downcase)#actually, google_oauth2
         auth.add_profile_link_from_oauth(data, Constants::GOOGLE)  
     elsif provider == Constants::LINKEDIN.downcase
        auth.add_profile_link_from_oauth(data, Constants::LINKEDIN, "public_profile")   
        auth.title = data.info["description"]
     elsif provider == Constants::FACEBOOK.downcase
        auth.add_profile_link_from_oauth(data, Constants::FACEBOOK)
     else
       raise "Unsupported provider #{provider}"
     end
     
     auth.set_name_from_oauth(data)
     auth.set_image_from_oauth(data)

     auth.save!
     
     return auth
  end
  
  def set_name_from_oauth(data)
     unless data.info["first_name"].blank?
       self.first_name = data.info["first_name"]
       unless data.info["last_name"].blank?
         self.last_name = data.info["last_name"]
       end
     else
       full_name = data.info["name"]
       unless full_name.blank?
         full_name_parts = full_name.split
         if full_name_parts.size > 1
           self.last_name = full_name_parts.pop
           self.first_name = full_name_parts.join(" ")
         else
           self.first_name = full_name_parts.join(" ")
         end
       end
     end
  end
  
  def set_image_from_oauth(data)
    image_path = data.info.image
    if image_path
        unless image_path.downcase.start_with?("https")   
         response = Net::HTTP.get_response(URI.parse(image_path))
         new_image_path = response['Location']
         # response.code is 301 or 302 in these cases
         unless new_image_path.nil?
           response = Net::HTTP.get_response(URI.parse(new_image_path ))
         end
        else
          uri = URI.parse(image_path)
          connection = Net::HTTP.new(uri.host, 443)
          connection.use_ssl = true
          connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
          
          response = connection.request_get("#{uri.path}?#{uri.query}")  
          
          if response.code != '200'
             raise "Error retrieving avatar image"
          end
              
        end
        content_type = response["Content-Type"]
        
        response_body = response.read_body #Body is binary data
        unless response_body.nil?  || response_body.length==0
          self.avatar = response_body
          self.avatar_content_type = content_type
        end
    end    
  end
  
  def add_profile_link_from_oauth(data, social_network, profile_url_key = nil)
    self.profile_links_map ||= Hash.new
    
    profile_url_key = social_network if profile_url_key.nil?
    profile_url = data.info.urls[profile_url_key]

    self.profile_links_map[social_network] = profile_url unless profile_url.blank?
  end
  
  def profiles_to_str
    res = ""
    res = self.profile_links_map.to_a.map {|a| "#{a.first}: #{a.last}"}.join("   ") unless self.profile_links_map.blank?
    
    return res
  end
end
