class Employer < ActiveRecord::Base
  include UserCommon
  
  serialize :join_us_widget_params_map, JSON
  
  attr_accessible  :company_name
  
  validates :first_name, :presence=> true
  validates :last_name, :presence=> true  
  validates :company_name, :presence => true

  has_many :jobs, :dependent => :destroy
  has_many :interviews, :dependent => :destroy
  has_many :ambassadors, :dependent => :destroy
  has_many :employer_plans, :dependent => :destroy
  
  def add_reminder!(linked_object_id, event_name)
    reminder = Reminder.new(:linked_object_id => linked_object_id, :employer=> self, :recipient_type=>:employer, :reminder_type => event_name)
    reminder.save!
  end    
  
  def reference_num(scramble = true)
    Utils.reference_num(self, scramble)
  end
  
  def self.find_by_ref_num(ref_num, scramble = true)
    Utils.find_by_reference_num(Employer, ref_num, scramble)  
  end  
  
  def self.happy_get_going_text
   "Get in touch with professionals worth talking to."
  end
  
  # Method  is used only in  verify.js.erb.  
  def self.capabilities_header
      ""
  end
  # Used to build email message
  def self.reason_to_verify
    ""
  end

  # Used in  flash
  def self.short_reason_to_verify
    "proceed"
  end
 
 def has_active_ambassadors?
   return self.ambassadors.only_active.any?
  end
  
  def self.homepage_description
    "employer page"
  end

  def self.remember_token_key
    :remember_token_employer
  end
  
  def unsubscribe 
    premium_plan = self.current_plan.tier > Constants::TIER_FREE
    if premium_plan
      plan = self.employer_plans.build(:tier => Constants::TIER_FREE, :monthly_price => Utils::monthly_price( Constants::TIER_FREE))
      plan.save!
    end
    
    self.jobs.where("status <> ?", Job::CLOSED).each do |job|
      job.shutdown!(Interview::CLOSED_BY_EMPLOYER)
    end
  end
  
  def current_plan
    employer_plans.order("created_at").last
  end
  
  def active_jobs
    self.jobs.where("status = ?", Job::LIVE)
  end
  
  # Returns array of Employers, where each employer object has an additional field which is not in the Employer class--employer.contacts_count.
  def self.count_infointerviews(*statuses)
    Employer.joins(:jobs => :infointerviews).select("count(infointerviews.id) as contacts_count, employers.*").where("infointerviews.status in (#{statuses.join(', ')})").group("employers.id")
  end
  
  def all_generated_leads_count(job_statuses = [Job::LIVE, Job::CLOSED]) # all leads the employer is notified about, even for closed jobs
    Infointerview.joins(:job).where("jobs.employer_id = ? and jobs.status in (?) and infointerviews.status in (?)", 
                                    id, job_statuses, [Infointerview::NEW, Infointerview::ACTIVE_LEAD, Infointerview::CLOSED_BY_EMPLOYER]).count # if employer closes it it's still a lead
  end
  
  def last_active_leads(count)
    Infointerview.joins(:job).where("jobs.employer_id = ? and jobs.status in (?) and infointerviews.status in (?)", 
                                    id, [Job::LIVE], [Infointerview::NEW, Infointerview::ACTIVE_LEAD]).order("created_at DESC").limit(count)
  end  
  
  def shares_statistics
    Share.joins(:ambassador).where("ambassadors.employer_id = ?", id).group("shares.network").select("shares.network, count(*) as shares_count, sum(shares.click_counter) as clicks_count, sum(shares.lead_counter) as leads_count")
  end
  
  def active_ambassadors_with_share_statistics
    Ambassador.joins(:employer).joins("LEFT OUTER JOIN shares ON shares.ambassador_id = ambassadors.id").where("ambassadors.status = ? and ambassadors.employer_id = ?", Ambassador::ACTIVE, id).group("ambassadors.id").select("ambassadors.*, count(shares.id) as shares_counter, sum(shares.click_counter) as clickback_counter, sum(shares.lead_counter) as leads_counter")
  end
  
  def active_jobs_with_share_statistics
    jobs_with_share_statistics_by_status(Job::LIVE)
  end
  
  def jobs_with_share_statistics_by_status(*status)
    Job.jobs_with_share_statistics_by_status(status).joins(:employer).where("jobs.employer_id = ?", id)
  end  
  
  def join_us_widget_running?
    now = Time.parse(ActiveRecord::Base.connection.select_value("SELECT CURRENT_TIMESTAMP"))
    return !join_us_widget_heartbeat.nil? && now - join_us_widget_heartbeat < 24.hours
  end
  
  def inspect
    jobs_str = jobs.collect {|job| "#{job.id}"}.compact.join(", ")
    
    parts = [
    "--------- Employer (id:#{self.id}) ---------",
    "** Created at #{self.created_at} (#{((Time.now - self.created_at)/(3600 * 24)).to_i} days ago), status = #{self.status}, tier = #{self.current_plan.name}, sample = #{self.sample}",
    "** #{self.company_name}",
    "** #{self.first_name} #{self.last_name} #{self.email}",
    "** Job ids: #{jobs_str}"
    ]
    parts.join("\n").concat("\n")
  rescue Exception => e
    logger.error "Inspect failed for #{self.class}: #{e}"
    super.inspect
  end
end
