class Infointerview < ActiveRecord::Base
  attr_accessible :email, :first_name, :job_id, :last_name, :profiles, :status, :user_id
  
  validates :job_id, :presence => true
  validates :email, :presence => true, :format=> { :with=> Constants::VALID_EMAIL_REGEX }, :length => { :maximum => 255 }
  validates :first_name, :presence => true, :length => { :maximum => 35 }
  validates :last_name, :presence => true, :length => { :maximum => 35 }
  validates_length_of :profiles, :maximum => 500
  
  belongs_to :job
  belongs_to :user
  belongs_to :auth
  belongs_to :referred_by_ambassador, :class_name => :Ambassador, :foreign_key => :referred_by
  
  has_many :followups, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  
  # for :status
  NEW = 0
  #VETTED_BY_FYI = 10
  #CLOSED_EXPIRED = 12
  ACTIVE_EMPLOYER_NOTIFIED = 13
  ACTIVE_SEEN_BY_EMPLOYER = 15
  #ACTIVE_LEAD_INVOLVING_AMBASSADOR = 20
  CLOSED_BY_FYI = 100 # not in use any more??? 1 record in production still has status 100
  CLOSED_BY_EMPLOYER = 110
  #ACTIVE_LEAD_AMBASSADOR_NOTIFIED = 200
  
  def reference_num(scramble = true)
    Utils.reference_num(self, scramble)
  end
  
  def self.find_by_ref_num(ref_num, scramble = true)
    Utils.find_by_reference_num(Infointerview, ref_num, scramble)  
  end  
  
  def close_by_fyi!
    self.update_attribute(:status, Infointerview::CLOSED_BY_FYI)
    self.followups.only_active.update_all(:status => Followup::CLOSED)
  end
  
  def status_one_of?(*statuses)
    statuses.include?(status)
  end  
  
  def employer
    self.job.employer
  end
  
  def full_candidate_name
    "#{self.first_name} #{self.last_name}"
  end
  
  def inspect 
    parts = [
    "------------------------------------------------------------------------",
    "** Created at #{self.created_at} (#{((Time.now - self.created_at)/(3600 * 24)).to_i} days ago), status = #{self.status}",
    "--------- Infointerview (id:#{self.id}, job_id:#{self.job_id}) ---------",
    "** #{self.full_candidate_name} - #{self.email}",
    "** Professional profiles: \"#{self.profiles}\"",
    "** ReferredBy id: #{self.referred_by}",
    "** User id: #{self.user_id}",
    "** Employer id: #{self.employer.id}" ,
    "** Company: #{self.job.company_name}",
    "** Position: #{self.job.position_name} in #{self.job.all_location_parts.join(' / ')}"
    ]
    
    parts << "** Resume file: #{Cloudinary::Utils.cloudinary_url(self.resume_doc_id, :resource_type => :raw, :secure => true )}" unless self.resume_doc_id.nil?
    
    parts.join("\n").concat("\n")
    
  rescue Exception => e
    logger.error "Inspect failed for #{self.class}: #{e}"
    super.inspect    
  end  
end
