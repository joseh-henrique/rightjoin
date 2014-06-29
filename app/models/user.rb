class User < ActiveRecord::Base
  include UserCommon

  belongs_to :location, :class_name => "LocationTag"
  
  belongs_to :current_position, :class_name => "PositionTag"
  belongs_to :wanted_position, :class_name => "PositionTag"
  
  has_many :user_skills, :dependent => :destroy
  has_many :user_job_qualifiers, :dependent => :destroy
  has_many :interviews, :dependent => :destroy  
  has_many :company_ratings, :dependent => :destroy
  has_many :infointerviews, :dependent => :nullify

  validates :current_position_id, :presence=> true
  validates :wanted_position, :presence=> true
  validates :first_name, :presence=> true
  validates :last_name, :presence=> true
  validate :check_valid_location
  validates :locale, :presence => true # like en, en-IL
  
  validates :wanted_salary, :presence => true
  validates :wanted_salary, :numericality => {:greater_than_or_equal_to  => 0}, :if => Proc.new { |user| !user.wanted_salary.blank? }

  validates_length_of :first_name, :maximum => 60
  validates_length_of :last_name, :maximum => 60
  validates_length_of :resume, :maximum => 500
  validates_length_of :free_text, :maximum => 250
  validates_length_of :contact_info, :maximum => 120
  
  # IMPORTANT: never change the order!!! The index in this array is used to persist the aspiration.
  ASPIRATIONS = 
      [{:label => "I want to work on something big. Challenge me!", :reason => "It's a challenging job and might be just what you're looking for."},
      {:label => "I want to have more influence in the project I work on.", :reason => "The job will provide the opportunity for impact in your project, and could be just the thing you're looking for."},
      {:label => "I want to take ownership of a challenging project.", :reason => "You'll be able to take ownership on a challenging project."},
      {:label => "I need to work with A-players, so I can keep on learning.", :reason => "They want to give you the opportunity to learn from strong colleagues."},
      {:label => "I want to do something rewarding; something that makes someone's life better.", :reason => "It's in a project aimed at making people's lives better, and it could be right up your alley."},
      {:label => "I need a change of scenery; I want to do something different.", :reason => "It's a job that offers some new and different opportunities. Ask them about it."}]
  
  def check_valid_location
    if (self.location.nil? && self.can_relocate != true && self.can_telecommute != true)
      errors.add(:model_users, "At least one location option must be specified.")
    end
  end
  
  def self.find_by_ref_num(ref_num, scramble = false)
    Utils.find_by_reference_num(User, ref_num, scramble)
  end
  
  def current_position_name
    res = ""
    unless self.current_position.nil?
      res = self.current_position.name
    end
  end
  
  def wanted_position_name
    res = ""
    unless self.wanted_position.nil?
      res = self.wanted_position.name
    end    
  end
  
  def all_location_parts
    [ self.location_name.blank? ? nil : self.location_name, 
      self.can_telecommute == true ? Constants::TELECOMMUTE  : nil, 
      self.can_relocate == true ?Constants::ANYWHERE: nil ].compact
  end
  
  def location_name
    res = ""
    unless self.location.nil?
      res = self.location.name
    end    
  end
  
  def latitude
    res = nil
    unless self.location.nil?
      res = self.location.latitude
    end
  end
  
  def longitude
    res = nil
    unless self.location.nil?
      res = self.location.longitude
    end
  end  

  def increment_num_recommended
    update_attribute(:num_recommended, self.num_recommended + 1)
  end
  
  def self.default_paginate(params, select, filter_conditions, orderby)
    array_of_selects = []
    array_of_selects << "*"
    array_of_selects += select
    select_str = self.to_conditions_str(array_of_selects, ", ")    
    
    array_of_conditions = []
    array_of_conditions << ["status = ?", UserConstants::VERIFIED]
    array_of_conditions += filter_conditions 
    conditions_str = self.to_conditions_str(array_of_conditions, " and ")
    
    array_of_order_by = []
    array_of_order_by += orderby
    array_of_order_by << "created_at DESC"
    order_by_str = self.to_conditions_str(array_of_order_by, ", ")
    order_by_str = "ORDER BY #{order_by_str}" unless order_by_str.blank?
    
    sql = "SELECT %{select} FROM users WHERE %{conditions} %{order_by}" % [:select => select_str,:conditions => conditions_str, :order_by => order_by_str]

    users = User.paginate_by_sql(sql, :page => params[:page], :per_page => 10)
    ActiveRecord::Associations::Preloader.new(users, [:location, :current_position, :wanted_position, {:user_job_qualifiers => :job_qualifier_tag}, {:user_skills => :skill_tag}]).run()
    
    users
  end
  
  def add_reminder!(linked_object_id, event_name)
    reminder = Reminder.new(:linked_object_id => linked_object_id, :user=> self, :recipient_type=>:user, :reminder_type => event_name)
    reminder.save!
  end
  
  def self.match(job, since = 10.years.ago)
    cond = []
    
    cond << ["wanted_position_id = ?", job.position.id]
    cond << ["status = ?", UserConstants::VERIFIED]
    cond << ["locale = ?", job.locale]
    cond << ["created_at > ?", since]
    
    if job.location.relocation?
        cond << ["can_relocate = ?", true]
    elsif job.location.telecommute?
        cond << ["can_telecommute = ?", true]
    elsif job.location.coordinates?
      cond << ["? <= northmost", job.location.latitude]
      cond << ["? >= westmost", job.location.longitude]
      cond << ["? >= southmost", job.location.latitude]
      cond << ["? <= eastmost", job.location.longitude]
    else
      cond << ["location_id = ?", job.location.id]
    end
    
    cond << ["NOT EXISTS (SELECT * FROM interviews as i WHERE i.user_id = u.id AND i.job_id = ?)", job.id]
    
    left = cond.collect {|x| x.first }
    right = cond.collect {|x| x.last }
    
    full_conditions = [left.join(" and ")] + right
    conditions_str = User.sanitize_conditions(full_conditions)

    sql = "SELECT * FROM users as u WHERE %{conditions} ORDER BY created_at DESC" % [:conditions => conditions_str]
    
    users = find_by_sql(sql)
  end
  
  def self.remember_token_key
    :remember_token
  end
  
 def self.capabilities_header
    "Pings from employers appear here. Check it out."
 end

  def self.happy_get_going_text
   "Smile, as employers ping you and ask you to ping them back."
  end
  
  def self.reason_to_verify
    " and start getting some great offers"
  end
  
  def self.short_reason_to_verify
    "get some great offers"
  end

  def self.homepage_description
    "dashboard page"
  end
  
  # like us, uk, il
  def country_code
    I18n.t(:country_code, :locale => self.locale)
  end
  
  def assign_all_location_attrs(new_location, can_telecommute, can_relocate)
    self.can_relocate = can_relocate
    self.can_telecommute = can_telecommute
    self.assign_location(new_location)
  end
  
  def assign_location(new_location)
    self.location = new_location
    
    self.northmost = nil
    self.southmost = nil
    self.westmost = nil
    self.eastmost = nil
    
    if new_location && new_location.coordinates? 
      search_radius_in_miles = I18n.t(:search_radius_in_miles, self.locale).to_i
      bounding_box = DistanceUtils::bounding_box(new_location.latitude, new_location.longitude, search_radius_in_miles)
      self.assign_attributes(bounding_box, :without_protection => true)
    end
  end
  
  def unsubscribe
    self.interviews.all.each do |interview|
      interview.close_expired!
    end
    deactivate
  end
  
  def inspect
    skills_str = user_skills.collect {|skill| "#{skill.skill_tag.name}:#{skill.seniority}"}.compact.join(", ")
    requirements_str = user_job_qualifiers.collect {|req| "#{req.job_qualifier_tag.name}"}.compact.join(", ")
    
    parts = [
    "--------- Candidate (id:#{self.id}, refid:#{reference_num}) ---------",
    "** Created at #{self.created_at} (#{((Time.now - self.created_at)/(3600 * 24)).to_i} days ago), status = #{self.status}, sample = #{self.sample}",
    "** #{self.email} #{self.contact_info} #{self.first_name} #{self.last_name} \"#{self.locale}\"",
    "** #{self.current_position_name} => #{self.wanted_position_name} in #{self.all_location_parts.join(" / ")}",
    "** Short message: \"#{self.free_text}\"",
    "** Professional profiles: \"#{self.resume}\"",
    "** Skills: #{skills_str}",
    "** Aspiration: #{self.aspiration.nil? ? "" : ASPIRATIONS[self.aspiration][:label]}",
    "** Requirements: #{requirements_str}",
    "** Wanted salary: #{self.wanted_salary}",
    "** Num. recommended: #{self.num_recommended}"
    ]
    parts.join("\n").concat("\n")
    
  rescue Exception => e
    logger.error "Inspect failed for #{self.class}: #{e}"
    super.inspect    
  end
end