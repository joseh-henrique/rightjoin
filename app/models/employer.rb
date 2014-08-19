class Employer < ActiveRecord::Base
  include UserCommon
  
  serialize :join_us_widget_params_map, JSON
  
  attr_accessible  :company_name, :reminder_body, :reminder_subject, :reminder_period
  
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
    self.jobs.where("status <> ?", Job::CLOSED).each do |job|
      job.shutdown!(Interview::CLOSED_BY_EMPLOYER)
    end
  end
  
  def current_plan
    employer_plans.order("created_at").last
  end
  
  def active_jobs
    self.jobs.where("status <> ?", Job::CLOSED)
  end
  
  def published_jobs
    self.jobs.where("status = ?", Job::PUBLISHED)
  end
  
  def has_active_jobs_with_empty_ad_url?
    active_jobs.where("ad_url is null or ad_url = ''").count > 0
  end
  
  def self.employer_ids_for_ambassador_reminder
    # have active jobs, active ambassadors and reminder period > 0
    Employer.joins(:jobs,:ambassadors).where("employers.reminder_period > ? and jobs.status = ? and ambassadors.status = ?", 0, Job::PUBLISHED, Ambassador::ACTIVE).pluck("distinct employers.id")
  end
  
  # Returns array of Employers, where each employer object has an additional field which is not in the Employer class--employer.contacts_count.
  def self.count_infointerviews(*statuses)
    Employer.joins(:jobs => :infointerviews).select("count(infointerviews.id) as contacts_count, employers.*").where("infointerviews.status in (#{statuses.join(', ')})").group("employers.id")
  end
  
  def all_generated_leads_count(job_statuses = [Job::PUBLISHED, Job::CLOSED]) # all leads the employer is notified about, even for closed jobs
    Infointerview.joins(:job).where("jobs.employer_id = ? and jobs.status in (?) and infointerviews.status in (?)", 
                                    id, job_statuses, [Infointerview::NEW, Infointerview::ACTIVE_LEAD, Infointerview::CLOSED_BY_EMPLOYER]).count # if employer closes it it's still a lead
  end
  
  def last_active_leads(count)
    Infointerview.joins(:job).where("jobs.employer_id = ? and jobs.status = ? and infointerviews.status in (?)", 
                                    id, Job::PUBLISHED, [Infointerview::NEW, Infointerview::ACTIVE_LEAD]).order("created_at DESC").limit(count)
  end
  
  def new_leads
    Infointerview.joins(:job).where("jobs.employer_id = ? and jobs.status = ? and infointerviews.status = ?", 
                                    id, Job::PUBLISHED, Infointerview::NEW).order("infointerviews.created_at DESC")
  end
  
  def leads_with_unseen_comments
    Infointerview.select("infointerviews.*, count(infointerviews.id) as new_comments_count").joins(:job, :comments).where("jobs.employer_id = ? and jobs.status = ? and infointerviews.status = ? and comments.ambassador_id is not null and comments.status in (?)", 
                          id, Job::PUBLISHED, Infointerview::ACTIVE_LEAD, [Comment::STATUS_NEW, Comment::STATUS_NOT_SEEN]).group("infointerviews.id").order("infointerviews.created_at DESC")
  end
  
  def shares_statistics
    Share.joins(:ambassador).where("ambassadors.employer_id = ?", id).group("shares.network").select("shares.network, count(*) as shares_count, sum(shares.click_counter) as clicks_count, sum(shares.lead_counter) as leads_count")
  end
  
  def active_ambassadors_with_share_statistics
    Ambassador.joins(:employer).joins("LEFT OUTER JOIN shares ON shares.ambassador_id = ambassadors.id").where("ambassadors.status = ? and ambassadors.employer_id = ?", Ambassador::ACTIVE, id).group("ambassadors.id").select("ambassadors.*, count(shares.id) as shares_counter, sum(shares.click_counter) as clickback_counter, sum(shares.lead_counter) as leads_counter")
  end
  
  def active_jobs_with_share_statistics
    jobs_with_share_statistics_by_status(Job::DRAFT, Job::PUBLISHED)
  end
  
  def jobs_with_share_statistics_by_status(*status)
    Job.jobs_with_share_statistics_by_status(status).joins(:employer).where("jobs.employer_id = ?", id)
  end  
  
  def join_us_widget_running?
    now = Time.parse(ActiveRecord::Base.connection.select_value("SELECT CURRENT_TIMESTAMP"))
    return !join_us_widget_heartbeat.nil? && now - join_us_widget_heartbeat < 24.hours
  end
  
  def reminder
    default_subject = "Take a break and share!"
    default_body = "Hi [first-name],\n\n"\
              "This is a friendly reminder to share our job postings and find us some good colleagues.\n\n" <<
               "The message gets noticed better after you share it a few times. It takes two clicks and no more than 30 seconds of your time.\n\n"\
              "[team-page-url]\n\n"\
              "Regards,\n\n"\
              "#{self.first_name}"# TODO Escape this. But a name like <script>1/0</script> is stripped out in email clients, so this is not a huge problel

   {:subject => self.reminder_subject.blank? ? default_subject : self.reminder_subject,
    :body => self.reminder_body.blank? ? default_body : self.reminder_body,
    :period => self.reminder_period}
  end
  
  def team_invitation_template
    default_subject = "Talking with potential future colleagues"
    default_salutation = "Hi"
    default_body = "We're looking for some smart developers to work with us at #{self.company_name}.\n\n" <<
          "#{Constants::SHORT_SITENAME} gives us a beautiful ad in which our current developers are the highlight. " << 
          "It has social sharing tools to help you spread it.\n\n" << 
          "Experienced developers then ping us through this ad. We may connect a few developers with you for a chat about working here.\n\n" <<
          "Please sign in at [team-page-url]\n\n" <<
          "Regards,\n" <<
          "#{self.first_name}"
          
   {:subject => self.invitation_subject.blank? ? default_subject : self.invitation_subject,
    :salutation => self.invitation_salutation.nil? ? default_salutation : self.invitation_salutation,
    :body => self.invitation_body.blank? ? default_body : self.invitation_body}
  end
  
  def self.send_pending_reminders_to_all_ambassadors
    counter = 0
    
    employer_ids = Employer.employer_ids_for_ambassador_reminder
    employer_ids.each do |id|
      employer = Employer.find(id)
      period = employer.reminder_period
      now = Time.parse(ActiveRecord::Base.connection.select_value("SELECT CURRENT_TIMESTAMP"))
      
      employer.ambassadors.each do |ambassador|
        if ambassador.should_remind(employer.reminder[:period])
          begin
            new_msg = FyiMailer.create_ambassador_reminder_message(ambassador, employer.reminder[:subject], employer.reminder[:body])
            Utils.deliver new_msg
            counter += 1
            
            ambassador.update_attributes(:reminder_sent_at => now)
          rescue Exception => e
            # We swallow the exception so that one failure does not cause failure in all
            logger.error e
          end
        end
      end
    end
    
    return counter
  end    
  
  def create_comment!(infointerview_id, body)
    c = Comment.new
    c.infointerview_id = infointerview_id
    c.body = body
    c.created_by = Comment::CREATED_BY_EMPLOYER
    c.save!
  end

  def inspect
    jobs_str = jobs.collect {|job| "#{job.id}"}.compact.join(", ")
    
    parts = [
    "--------- Employer (id:#{self.id}) ---------",
    "** Created at #{self.created_at} (#{((Time.now - self.created_at)/(3600 * 24)).to_i} days ago), status = #{self.status}, tier = #{self.current_plan.name}, sample = #{self.sample}",
    "** #{self.company_name}",
    "** #{self.first_name} #{self.last_name} #{self.email}",
    "** Enable ping: #{self.enable_ping}",
    "** Job ids: #{jobs_str}"
    ]
    parts.join("\n").concat("\n")
  rescue Exception => e
    logger.error "Inspect failed for #{self.class}: #{e}"
    super.inspect
  end
end
