class Reminder < ActiveRecord::Base
  belongs_to :employer #nullable
  belongs_to :user #nullable
  
  validates :reminder_type, :presence => true
  
  PERSONAL_CANDIDATE_WELCOME_MESSAGE = :personal_candidate_welcome_message
  PERSONAL_EMPLOYER_WELCOME_MESSAGE = :personal_employer_welcome_message 
  ADMIN_SUMMARY_SENT = :admin_summary_sent
  BOARDS_UPDATE_ANNOUNCEMENT = :boards_update_announcement
  AMB_SERVICE_ANNOUNCEMENT = :amb_service_announcement
  
  USER_ACCOUNT_ACTIVATED = :user_account_activated
  EMPLOYER_ACCOUNT_ACTIVATED = :employer_account_activated
  JOB_CREATED = :job_created
  JOB_CLOSED = :job_closed
  COMPANY_RATED_ACTION = :company_rated_action
  NEW_LEAD = :new_lead
  
  scope :personal_welcome_message, lambda {|user| 
    if user.instance_of?(User)
      where(:linked_object_id => user.id, :reminder_type => PERSONAL_CANDIDATE_WELCOME_MESSAGE).order("created_at desc")
    else # user.instance_of?(Employer)
      where(:linked_object_id => user.id, :reminder_type => PERSONAL_EMPLOYER_WELCOME_MESSAGE).order("created_at desc")
    end
  }
  
 
  def self.create_event!(linked_object_id, event_name)
    reminder = Reminder.new(:linked_object_id => linked_object_id, :reminder_type => event_name)
    reminder.save!
  end

  # no attributes are attr_accessible 
  def self.send_jobs_update_to_engineers(&block)
     max_engineer_emails = FyiConfiguration.fetch_with_default("max_engineer_emails", 30).to_i
     counter = 0
     invites = []
     Interview.unscoped.where("status = ?", Interview::APPROVED).order('user_id, created_at asc').each do |invite|
   
         if counter >= max_engineer_emails 
             logger.error "The limit of max #{max_engineer_emails} send_jobs_update_to_engineers emails exceeded! Bug or grand success???"
             break
         end
         
         if invites.any? && invites.last.user_id != invite.user_id
           sent_num = send_jobs_update_to_one_engineer(invites, block)
           invites = []
           counter += sent_num
         end
         invites << invite
     end
     
     unless invites.empty?
         sent_num = send_jobs_update_to_one_engineer(invites, block)
         counter += sent_num
     end
    
     puts "Jobs update sent to #{counter} engineers"    
  end
  
  
  def self.send_jobs_update_to_one_engineer(invites, block)
    ret = 0
    begin

      if invites.first.user.status == UserConstants::VERIFIED
        block.call invites
        ret += 1
        puts "Update sent to engineer: #{invites.first.user.email}"
      else
        puts "Update wasn't sent to engineer: #{invites.first.user.email}: inactive account"
      end
      
      invites.each { |i| i.set_contacted }
      
    rescue Exception => e
      # We swallow the exception so that one failure does not cause failure in all
      logger.error e
    end
    return ret
  end
  
  def self.send_jobs_update_to_employers(&block)
     max_employer_emails = FyiConfiguration.fetch_with_default("max_employer_emails", 30).to_i
     counter = 0
     all_jobs = []
     open_jobs = []
     just_expired_jobs = []
  
    # Here we query for all open jobs. However, before generating each mail, we close any expired jobs (see 13 lines down). 
    # So fyi_mailer will receive some closed jobs, all of which are recently expired.
    # This code does not account for employrs in   state  DEACTIVATED who still have open jobs. However, deactivation
    # can only be done manually for now, so that is unlikely.
     Job.active_with_share_statistics.order('employer_id, created_at asc').each do |job| 
       if counter >= max_employer_emails 
           logger.error "The limit of max #{max_employer_emails} send_jobs_update_to_employers emails exceeded! Bug or grand success???"
           break
       end
       
       if all_jobs.any? && all_jobs.last.employer_id != job.employer_id
         send_jobs_update_to_one_employer(all_jobs, open_jobs, just_expired_jobs, block)
         all_jobs = []
         open_jobs = []
         just_expired_jobs = []
         counter += 1
       end
       
       # auto-expire jobs, but only if it's a free plan
       if job.employer.current_plan.tier == Constants::TIER_FREE && job.expire_ads!(1.month)
         job.shutdown!(Interview::CLOSED_EXPIRED)
         just_expired_jobs << job
       else
         open_jobs << job
       end
       
       all_jobs << job
     end
     
     if all_jobs.any?
       send_jobs_update_to_one_employer(all_jobs, open_jobs, just_expired_jobs, block)
       counter += 1
     end

     puts "Jobs update sent to #{counter} employers"    
  end
  
  def self.send_jobs_update_to_one_employer(all_jobs, open_jobs, just_expired_jobs, block)
    begin
      block.call all_jobs, open_jobs, just_expired_jobs
      
      puts "Update sent to employer: #{all_jobs.first.employer.email}"
    rescue Exception => e
      # We swallow the exception so that one failure does not cause failure in all
      logger.error e
    end
  end

  def self.send_personal_welcome_message(model_class)
    recent_users = model_class.all(:conditions =>
       ["created_at > ? and status = ?",
         1.days.ago, UserConstants::VERIFIED])
     
    # Since we loop to send emails, we limit the number to avoid sending a flood of emails if there should be a bug.    
    max_emails = FyiConfiguration.fetch_with_default("max_welcome_emails", 30).to_i
    counter = 0
    recent_users.each do |user|
      if Reminder.personal_welcome_message(user).blank?
          yield user # The func which calls this function will send the email 
          
          if user.instance_of?(User)
            user.add_reminder!(user.id, PERSONAL_CANDIDATE_WELCOME_MESSAGE);
          else # user.instance_of?(Employer)
            user.add_reminder!(user.id, PERSONAL_EMPLOYER_WELCOME_MESSAGE);
          end
          
          counter += 1
          if counter >= max_emails 
             logger.error "The limit of max #{max_emails} send_personal_welcome_message messages exceeded! Bug or grand success???"
             break
          end
       end
    end
  end
  
  def self.send_admin_summary
    search_starting_from = Time.now - 1.day # look one day backwards
    last_admin_summary_reminder = Reminder.find_all_by_reminder_type(ADMIN_SUMMARY_SENT).last
    search_starting_from = last_admin_summary_reminder.created_at unless last_admin_summary_reminder.nil?
    
    events = Reminder.where("created_at > '#{search_starting_from}'")
    
    yield events
    
    create_event!(nil, ADMIN_SUMMARY_SENT)
  end
  
  # send 30 every day, until exhausted
  def self.send_amb_service_announcement_to_engineers
    num_to_send = 30
    users = User.where("status = ? and created_at < ? and (sample = ? or sample is null) and locale = ?", UserConstants::VERIFIED, Time.new(2014, 3, 5), false, Constants::LOCALE_EN)
                 .where("not exists (select * from reminders where users.id = reminders.user_id and reminders.reminder_type = ?)", Reminder::AMB_SERVICE_ANNOUNCEMENT).order("created_at asc")
                 .limit(num_to_send)
    users.each do |user|
      begin
        yield user
        user.add_reminder!(nil, Reminder::AMB_SERVICE_ANNOUNCEMENT)
      rescue Exception => e
        logger.error(e)

      end
    end
    return users.count
  end
  
  # update employers about new contacts
  def self.update_employers_about_new_contacts
     max_employer_emails = FyiConfiguration.fetch_with_default("max_employer_emails", 30).to_i
     counter = 0
     
     # in the employers array below, each employer object has an additional field which is not in the Employer class, namely employer.contacts_count.
     employers = Employer.count_infointerviews(Infointerview::NEW)
     employers.each do |employer|
       if counter < max_employer_emails
         yield employer
       end
       counter += 1
     end
  end
end
