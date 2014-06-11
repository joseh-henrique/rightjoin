class Interview < ActiveRecord::Base
  belongs_to :employer
  belongs_to :user
  belongs_to :job

  validates :user_id, :presence=> true
  validates :employer_id, :presence=> true  
  validates :job_id, :presence=> true
  
  default_scope :order => 'interviews.created_at DESC'
  
  # Run in cron script
  def self.close_expired
    recent_interviews = Interview.all(:conditions =>
       ["contacted_at > ? and status = ?",
         7.days.ago, Interview::CONTACTED_BY_EMPLOYER])

    recent_interviews.each do |interview|
      interview.close_expired!
    end
    
    puts "Closed #{recent_interviews.count} expired interviews"
  end
  
  def close_expired!
    self.update_attribute(:status, Interview::CLOSED_EXPIRED)  
  end
  
  def approve!
    self.update_attribute(:status, Interview::APPROVED)
  end
  
  def reject!
    self.update_attribute(:status, Interview::CLOSED_NOT_APPROVED)
  end
  
  def set_contacted
    begin
      self.contacted_at = Time.now
      self.status = Interview::CONTACTED_BY_EMPLOYER
      self.save!
    rescue Exception => e
      logger.error e
    end
  end
  
  def closed?
    status_one_of_splat?(CLOSED_BY_EMPLOYER, CLOSED_EXPIRED, CLOSED_NOT_APPROVED)
  end

  def status_one_of?(statuses)
    statuses.include?(status)
  end
  
  # An experimental variant which should probably replace status_one_of?
  def status_one_of_splat?(*statuses)
    statuses.include?(status)
  end
  
  def self.have_active_ambassadors?(ivws)
    has_amb = ivws.any?{|i|i.employer.has_active_ambassadors? } 
    return has_amb
  end
  
  def inspect
    parts = [
    "--------------------------------------------------------------------------------------------------------------------",
    "--------- Interview (id:#{self.id}, job id:#{job.id}, employer id:#{employer.id}, candidate id:#{user.id}) ---------",
    "** Created at #{self.created_at} (#{((Time.now - self.created_at)/(3600 * 24)).to_i} days ago), Status = #{status_to_str}",
    "#{job.inspect.strip}",
    "#{user.inspect.strip}",
    "---------------------------------------------------------------------------------------------------------------------"
    ]
    parts.join("\n").concat("\n")
    
  rescue Exception => e
    logger.error "Inspect failed for #{self.class}: #{e}"
    super.inspect    
  end    

  ######### INTERVIEW STATUSES ##############################################
  RECOMMENDED = 5 # FYI has recommended a candidate to the employer.
  AWAITING_APPROVAL = 7 # The employer invited a candidate, but FYI has not yet approved. 
  APPROVED = 8 # FYI approved an employer's invitation to a candidate, or else the invitation was a perfect match to the cnadidate and so approval was not needed 
  CONTACTED_BY_EMPLOYER = 10 # The biweekly email to the candidate mentioned the invitation
  CLOSED_BY_EMPLOYER = 1000
  CLOSED_NOT_APPROVED = 1005
  CLOSED_EXPIRED = 1010
  ############################################################################
  def status_to_str
    case self.status
    when RECOMMENDED
      "RECOMMENDED"
    when AWAITING_APPROVAL
      "AWAITING_APPROVAL"
    when APPROVED
      "APPROVED"      
    when CONTACTED_BY_EMPLOYER
      "CONTACTED_BY_EMPLOYER"
    when CLOSED_BY_EMPLOYER
      "CLOSED_BY_EMPLOYER"
    when CLOSED_EXPIRED
      "CLOSED_EXPIRED"
    when CLOSED_NOT_APPROVED
      "CLOSED_NOT_APPROVED"
    else
      "Undefined"
    end
  end
  
  
end
