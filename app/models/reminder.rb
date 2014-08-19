class Reminder < ActiveRecord::Base
  belongs_to :employer #nullable
  belongs_to :user #nullable
  
  validates :reminder_type, :presence => true
  
  PERSONAL_CANDIDATE_WELCOME_MESSAGE = :personal_candidate_welcome_message
  PERSONAL_EMPLOYER_WELCOME_MESSAGE = :personal_employer_welcome_message 
  ADMIN_SUMMARY_SENT = :admin_summary_sent
  BOARDS_UPDATE_ANNOUNCEMENT = :boards_update_announcement
  AMB_SERVICE_ANNOUNCEMENT = :amb_service_announcement
  RIGHTJOIN_MIGRATION_ANNOUNCEMENT = :rightjoin_migration_announcement
  
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
  
  # TODO all_jobs and open_jobs are the same now. So, remove open_jobs. Also, remove the unused_param that used to be just_expired jobs. 
  #(open_jobs used to represent those jobs which remained open in the current action-- in other words, excluding just_expired_jobs )
  #
  def self.send_jobs_update_to_employers(&block)
     max_employer_emails = FyiConfiguration.fetch_with_default("max_employer_emails", 30).to_i
     counter = 0
     all_jobs = []
     open_jobs = []
     unused_param = []  
  
    # This code does not account for employrs in   state  DEACTIVATED who still have open jobs. However, deactivation
    # can only be done manually for now, so that is unlikely.
     Job.published_with_share_statistics.order('employer_id, created_at asc').each do |job| 
       if counter >= max_employer_emails 
           logger.error "The limit of max #{max_employer_emails} send_jobs_update_to_employers emails exceeded! Bug or grand success???"
           break
       end
       
       if all_jobs.any? && all_jobs.last.employer_id != job.employer_id
         send_jobs_update_to_one_employer(all_jobs, open_jobs, unused_param, block)
         all_jobs = []
         open_jobs = []
         unused_param = []
         counter += 1
       end
       
       open_jobs << job
       all_jobs << job
     end
     
     if all_jobs.any?
       send_jobs_update_to_one_employer(all_jobs, open_jobs, unused_param, block)
       counter += 1
     end

     puts "Jobs update sent to #{counter} employers"    
  end
  
  def self.send_jobs_update_to_one_employer(all_jobs, open_jobs, unused_param, block)
    begin
 
      empr = all_jobs.first.employer
 
      block.call(empr, all_jobs, open_jobs, unused_param)
      
      puts "Update sent to employer: #{empr.email}"
    rescue Exception => e
      puts e.backtrace
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
  
  # send a few every time until exhausted
  def self.send_rightjoin_migration_announcement_to_engineers
    num_to_send  = FyiConfiguration.fetch_with_default("max_engineer_emails", 20).to_i
    date_migration_rj = Time.new(2014, 6, 30)
    users = User.where("status = ? and created_at < ? and (sample = ? or sample is null)", UserConstants::VERIFIED, date_migration_rj, false).where("not exists (select * from reminders where users.id = reminders.user_id and reminders.reminder_type = ?)", Reminder::RIGHTJOIN_MIGRATION_ANNOUNCEMENT).order("created_at asc").limit(num_to_send)
    users.each do |user|
      begin
        yield user
        user.add_reminder!(nil, Reminder::RIGHTJOIN_MIGRATION_ANNOUNCEMENT)
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
     
     ts = ActiveRecord::Base.connection.select_value("SELECT CURRENT_TIMESTAMP")
     
     # in the employers array below, each employer object has an additional field which is not in the Employer class, namely employer.contacts_count.
     employers = Employer.count_infointerviews(Infointerview::NEW)
     employers.each do |employer|
       if counter < max_employer_emails
         begin
            yield employer
            counter += 1
         
            # update statuses of all infoinerviews we just reported about to ACTIVE
            Infointerview.joins(:job => :employer).where("infointerviews.status = ? and infointerviews.created_at < ?", Infointerview::NEW, ts).where("jobs.employer_id = ?", employer.id).update_all(:status => Infointerview::ACTIVE_LEAD)
          rescue Exception => e
            logger.error(e)
          end
       end
     end
  end
  
  # update employers about new comments
  def self.update_employers_about_new_comments
     max_employer_emails = FyiConfiguration.fetch_with_default("max_employer_emails", 30).to_i
     counter = 0
     
     new_comments = Comment.get_new_comments_from_ambassadors.to_a

     new_comments.each do |comment|
       if counter < max_employer_emails
         begin
            yield comment
            counter += 1
         
            # from STATUS_NEW to STATUS_NOT_SEEN
            comment.status = Comment::STATUS_NOT_SEEN
            comment.save!
          rescue Exception => e
            logger.error(e)
          end
       end
     end
  end
end
