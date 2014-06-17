class Job < ActiveRecord::Base
  belongs_to :employer
  belongs_to :location, :class_name => "LocationTag"
  belongs_to :position, :class_name => "PositionTag"
  belongs_to :logo, :class_name => "Photo", :foreign_key => :logo_image_id
  
  has_many :interviews, :dependent => :destroy
  has_many :ads, :dependent => :destroy
  has_many :infointerviews, :dependent => :destroy
  has_many :shares, :dependent => :nullify
  
  validates :employer_id, :presence => true
  validates :position_id, :presence => true
  validates :description, :presence => true
  validates :location_id, :presence => true
  validates :company_name, :presence => true
  validates :position_id, :presence => true
  validates :locale, :presence => true # like en, en-IL
  
  validates :benefit1, :allow_blank => true, :length => { :maximum => 40 }
  validates :benefit2, :allow_blank => true, :length => { :maximum => 40 }
  validates :benefit3, :allow_blank => true, :length => { :maximum => 40 }
  validates :benefit4, :allow_blank => true, :length => { :maximum => 40 }
  
  default_scope :order => 'jobs.created_at DESC'
  
  LIVE = 1    # for :status
  CLOSED = 0 # for :status  
  
  NORMAL_JOB_DISPLAY_RANK = 100
  DESCRIPTION_MAX_LEN = 320

  def position_name
    res = ""
    unless self.position.nil?
      res = self.position.name
    end
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
  
  def assign_all_location_attrs(new_location, telecommuting, relocation)
    self.allow_relocation = relocation
    self.allow_telecommuting = telecommuting
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
 
  def shutdown!(interview_status)
    self.interviews.each do |interview|
      begin
        interview.status = interview_status
        interview.save!
      rescue Exception => e
   
        logger.error e
      end
    end
    
    # delete all associated ads
    self.ads.each do |ad|
      begin
        ad.destroy
      rescue Exception => e
        logger.error e
      end      
    end
    
    update_attributes(:status => CLOSED)
  end
  
  # returns true if all ads were expired
  def expire_ads!(timeout)
    all_expired = true
    
    self.ads.each do |ad|
      begin
        if ad.created_at < timeout.ago
          ad.destroy
        else
          all_expired = false
        end
      rescue Exception => e
        logger.error e
      end      
    end
    
    return all_expired
  end

  def closed?
    return status == CLOSED
  end
  
  def from_fyi
    return self.employer.email.match(/#{Constants::SITENAME_LC}$/)
  end
  
  
  def country_code#like uk, us, il
    I18n.t(:country_code, :locale => self.locale)
  end 
  
  def matches?(user)
    return true if self.from_fyi
    
    ret = false
  
  # Bounding-box Logic duplicated in 
  # - application_controller
  # - sample_data.rake
  # - user.rb

    if self.position.id == user.wanted_position.id || self.position.family_position && user.wanted_position.family_position && user.wanted_position.family_position.id == self.position.family_position.id
      if user.can_relocate && self.allow_relocation || 
        user.can_telecommute && self.allow_telecommuting || 
        user.location && self.location && user.location.id == self.location.id ||
        user.location && self.location && self.location.longitude && user.westmost && (self.location.longitude >= user.westmost && self.location.longitude <= user.eastmost) && (self.location.latitude <= user.northmost && self.location.latitude >= user.southmost)
        ret = true
      end
    end
    
    return ret
  end
  
  def benefits
    res = []
    res << self.benefit1 unless self.benefit1.blank?
    res << self.benefit2 unless self.benefit2.blank?
    res << self.benefit3 unless self.benefit3.blank?
    res << self.benefit4 unless self.benefit4.blank?
    return res
  end
  
  def active_boards
    Board.joins(:ads => :job).select("boards.*").where("jobs.id = ? and jobs.status = ?", self.id, Job::LIVE)
  end
  
  # throws exception if can't
  def can_recommend?(user)
    raise "A sample user could not be recommended" if user.sample
    raise "A deleted or unverified user could not be recommended" if user.deleted? || !user.verified?
    raise "Mismatched locales" if user.locale != self.locale
    
    old_interviews = self.interviews.find_by_user_id(user)
    raise "The user could not be recommended: another interview record was found" unless old_interviews.blank?
       
    return true
  end
  
  def all_generated_leads_count(job_statuses = [Job::LIVE, Job::CLOSED]) # all leads the employer is notified about, even for closed jobs
    Infointerview.joins(:job).where("jobs.id = ? and jobs.status in (?) and infointerviews.status in (?)", 
                                    id, job_statuses, [Infointerview::NEW, Infointerview::ACTIVE_LEAD, Infointerview::CLOSED_BY_EMPLOYER]).count # if employer closes it it's still a lead
  end
  
  def print_candidates(alternative_location, skill, max_count)
    begin
      candidates = list_candidates(alternative_location, skill, max_count)
      candidates.each do |one|
        puts one.inspect
        puts "\n---------------------------------------------------------------------------------"
      end
      puts "\nFound #{candidates.length} users"
    rescue Exception => e
      puts e.message
    end    
  end
  
  def list_candidates(alternative_location, skill, max_count)
    candidates = []
    
    max_count ||= 10
    counter = 0
    
    raise "Job position is closed" if self.closed?
    
    loc_obj = LocationTag.find_by_name(alternative_location) unless alternative_location.blank?
    loc_obj ||= self.location
    
    conditions = []
    if loc_obj.relocation?
      conditions << ["can_relocate = ?", true]
    elsif loc_obj.telecommute?
      conditions << ["can_telecommute = ?", true]
    elsif loc_obj.coordinates?
      conditions << ["? <= northmost", loc_obj.latitude]
      conditions << ["? >= westmost", loc_obj.longitude]
      conditions << ["? >= southmost", loc_obj.latitude]
      conditions << ["? <= eastmost", loc_obj.longitude]
    else
      conditions << ["location_id = ?", loc_obj.id]
    end
    
    pos_obj = self.position
    if pos_obj.family_id.nil?
      conditions << ["wanted_position_id = ?", pos_obj.id]
    else
      conditions << ["wanted_position_id in (select position_tags.id from position_tags where position_tags.family_id = ?)", pos_obj.family_id]
    end
    
    conditions << ["exists (select * from user_skills inner join skill_tags on user_skills.skill_tag_id = skill_tags.id where users.id = user_skills.user_id and skill_tags.name = ?)", skill] unless skill.blank?
    conditions << ["locale = ?", self.locale]
    
    select = []
    select << ["wanted_position_id = ? as primary_pos", pos_obj.id] if !pos_obj.nil? && !pos_obj.family_id.nil?
    
    orderby = []
    orderby << "primary_pos DESC" if !pos_obj.nil? && !pos_obj.family_id.nil?
    
    params = {:page => 1}
    
    keep_searching = true
    while keep_searching
      users = User.default_paginate(params, select, conditions, orderby)
      keep_searching = false if users.blank?
      
      users.each do |user|
        begin 
          if keep_searching
            can_recommend?(user)
            candidates << user
  
            counter += 1
            keep_searching = counter < max_count
          end
        rescue Exception => e
          puts e.message
        end
      end
      
      params[:page] += 1
    end
    
    candidates
  end  
  
  def recommend(user)
    new_interview = nil
    
    raise "Job is closed" if self.closed?
    
    begin
      can_recommend?(user)
      new_interview = self.interviews.create!({:employer_id => self.employer.id,:user_id => user.id, :status => Interview::RECOMMENDED})
      user.increment_num_recommended
    rescue Exception => e
       raise e
    end
    
    return new_interview
  end
  
  def all_location_parts
    [ self.location_name, 
      self.allow_telecommuting == true && !self.location_name.include?(Constants::TELECOMMUTE) ? Constants::TELECOMMUTE  : nil, 
      self.allow_relocation == true && !self.location_name.include?(Constants::RELOCATION) ? Constants::RELOCATION: nil ].compact
  end
  
  # The CSV file must have the following columns:
  # description, country-code, location, latitude, longitude, title, company, relocation, job-ad-url, kegerator, meaningful-jobs, bleeding-edge-tech, startup, open-source 
  def self.import_fyi_jobs(url_to_csv)
    new_jobs = []

    fyi_recruiter = Employer.find_by_email(Constants::FYI_RECRUITER_EMAIL)
    raise "Missing FYI employer" if fyi_recruiter.nil?    
    
    array_of_rows = DbFeeder.feed_from_url(url_to_csv) do |row, i|
      begin
        # mandatory fields
        locale = Constants::COUNTRIES[row["country-code"]]
        location = row["location"]
        title = row["title"]
        company_name = row["company"]
        ad_url = row["job-ad-url"]
        
        # belongs to at least 1 board (This is also filtered out in script f_after_review_prep_for_locale_normalization.rb)
        has_boards = false
        Board.all.each do |board|
          if Utils.to_bool(row[board.name])
            has_boards = true
            break
          end
        end
        
        # is the input alright?
        if [locale, location, title, company_name].select{|o| o.blank?}.blank? && has_boards
          old_job = nil
          old_job = Job.find_by_ad_url(ad_url) unless ad_url.blank?
          
          if old_job.nil? || old_job.closed?
            loc_obj = LocationTag.find_or_create_by_params({:location => location.downcase, :lat => row["latitude"], :lng => row["longitude"]})
            raise ActiveRecord::RecordInvalid.new(loc_obj) if loc_obj.errors.any?
            
            pos_obj = PositionTag.find_or_create_by_name(title.downcase)
            raise ActiveRecord::RecordInvalid.new(pos_obj) if pos_obj.errors.any?
            
            job = Job.new
            job.status = Job::LIVE
            job.locale = locale
            
            job.employer = fyi_recruiter
            
            job.position = pos_obj
            job.assign_all_location_attrs(loc_obj, Utils.to_bool(row["work-from-home"]) || location.include?(Constants::TELECOMMUTE), Utils.to_bool(row["relocation"]))
        
            job.description = Utils.truncate(row["description"], DESCRIPTION_MAX_LEN)
            job.company_name = company_name
            job.ad_url = ad_url
        
            job.save!
            Reminder.create_event!(job.id, Reminder::JOB_CREATED)
            new_jobs << job
            
            # post to boards
            Board.all.each do |board|
              if Utils.to_bool(row[board.name])
                ad = board.ads.build(:job_id => job.id)
                ad.save!
              end
            end
          else
            Rails.logger.info "Another job with the same ad URL found. Skipping..."
          end
        end
      rescue  Exception => e
        Rails.logger.error e
      end      
    end
    
    return {:jobs => new_jobs, :total_rows_count => array_of_rows.count}
  end
  
  def self.default_paginate(params, select, filter_conditions, orderby)
    array_of_selects = []
    array_of_selects << "*"
    array_of_selects += select
    select_str = self.to_conditions_str(array_of_selects, ", ")    
    
    array_of_conditions = []
    array_of_conditions << ["status = ?", Job::LIVE]
    array_of_conditions += filter_conditions 
    conditions_str = self.to_conditions_str(array_of_conditions, " and ")
    
    array_of_order_by = []
    array_of_order_by += orderby
    array_of_order_by << "created_at DESC"
    order_by_str = self.to_conditions_str(array_of_order_by, ", ")
    
    sql = "SELECT %{select} FROM jobs WHERE %{conditions} ORDER BY %{order_by}" % [:select => select_str,:conditions => conditions_str, :order_by => order_by_str]

    jobs = Job.paginate_by_sql(sql, :page => params[:page], :per_page => 10)
    ActiveRecord::Associations::Preloader.new(jobs, [:location, :position, :ads]).run()
    
    jobs
  end
  
  def self.active_with_share_statistics
    self.jobs_with_share_statistics_by_status(Job::LIVE)
  end
  
  def self.jobs_with_share_statistics_by_status(*status)
    Job.unscoped.joins("LEFT OUTER JOIN shares ON shares.job_id = jobs.id").where(status: status).group("jobs.id").select("jobs.*, count(shares.id) as shares_counter, sum(shares.click_counter) as clickback_counter, sum(shares.lead_counter) as leads_counter")
  end
  
  def get_photo(index) 
    photo = nil
    photo_id = self.attributes["image_#{index}_id"]
    
    photo = Photo.find_by_id(photo_id) unless photo_id.nil?
    
    return photo
  end
  
  def get_photos
    photos = []
    
    (1..3).each do |i|
      photos << self.get_photo(i)
    end
    
    return photos.compact
  end
  
  def inspect
    recommended_users_str = interviews.select {|i| i.status == Interview::RECOMMENDED}.map{|i|i.user.id}.compact.join(", ")
    
    parts = [
    "--------- Job (id:#{self.id}) ---------",
    "** Created at #{self.created_at} (#{((Time.now - self.created_at)/(3600 * 24)).to_i} days ago), status = #{self.status}, \"#{self.locale}\"",
    "** #{self.company_name} (id:#{self.employer_id}) ==== #{position.name} ==== #{all_location_parts.join(' / ')}",
    "** URL: #{self.ad_url.to_s}",
    "** #{Utils.truncated_plaintext(self.description, :length => DESCRIPTION_MAX_LEN)}",
    "** Techstack: #{self.tech_stack_list}",
    "** Boards: #{self.ads.map{|ad|ad.board.title}.join(', ')}",
    "** Benefits #{self.benefits.join(', ')}",
    "** Invites #: #{self.invites_counter}",
    "** Recommended users: #{recommended_users_str}"
    ]
    parts.join("\n").concat("\n")

  rescue Exception => e
    logger.error "Inspect failed for #{self.class}: #{e}"
    super.inspect    
  end  
end
