class LocationTag < ActiveRecord::Base  
  validates :name, :presence => true, :uniqueness => true, :length => { :maximum => 60 }
  has_many :users, :dependent => :destroy, :foreign_key => 'location_id'
  has_many :jobs, :dependent => :destroy, :foreign_key => 'location_id'
  before_save { |tag| tag.name = tag.name.downcase.strip }
  
  def self.find_or_create_by_params(params)
    location_obj = nil
    
    location_str = params[:location]
    unless location_str.blank?
      location_obj = LocationTag.find_by_name(location_str)
      if location_obj.nil?
        location_obj = LocationTag.new(:name => location_str)
      end
      
      unless params[:lat].blank? || params[:lng].blank?
        location_obj.latitude = params[:lat].to_f
        location_obj.longitude = params[:lng].to_f
        location_obj.priority = 1 if location_obj.priority == 0
      end 
      
      location_obj.save! if location_obj.changed? 
    end
    
    location_obj
  end
  
  def self.user_default_options
    Rails.cache.fetch("user_default_location_options&locale=#{I18n.locale.to_s}") do
      remote_obj = LocationTag.find_or_create_by_params(:location => Constants::TELECOMMUTE)
      relocation_obj = LocationTag.find_or_create_by_params(:location => Constants::RELOCATION )
      [{:id => remote_obj.id, :label => remote_obj.name}, {:id => relocation_obj.id, :label => relocation_obj.name}]
      
    end
  end
  
  def self.employer_default_options
    Rails.cache.fetch("employer_default_location_options&locale=#{I18n.locale.to_s}") do
      remote_obj = LocationTag.find_or_create_by_params(:location =>  Constants::TELECOMMUTE)
      [{:id => remote_obj.id, :label => remote_obj.name}]
    end
  end
  
  def fix_coordinates_for_associated_users_and_jobs(lat, lng)
    self.latitude = lat
    self.longitude = lng
    self.save!
    
    self.replace_locations_for_associated_objects(self)
  end
  
  def replace_locations_for_associated_objects(new_loc)
    self.users.each do |user| 
      user.assign_location(new_loc) 
      user.save!
    end
    
    self.jobs.each do |job| 
      job.assign_location(new_loc)
      job.save!
    end
    
    self.reload
  end
  
  def coordinates?
    !latitude.nil? && !longitude.nil?
  end
  
  def relocation?
    self.name == Constants::RELOCATION
  end
  
  def telecommute?
    self.name == Constants::TELECOMMUTE 
  end
end
