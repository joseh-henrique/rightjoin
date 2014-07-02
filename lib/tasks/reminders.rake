namespace :cron do
  desc "Send reminders"
  
  # task :remind_pending_user_response => :environment do
    # if Time.now.monday? || Time.now.thursday?
      # Reminder.remind_pending_user_response do |interview|
          # new_msg = FyiMailer.create_pending_user_response_reminder_email(interview)
          # Utils.deliver new_msg
          # puts "Reminder sent to candidate: #{interview.user.email}"
      # end
      # puts "Pending-user-response reminders processed"
    # end
  # end
#   
  # task :remind_review_recommended => :environment do
    # Reminder.remind_review_recommended do |employer, job|
        # new_msg = FyiMailer.create_review_recommended_email(employer, job)
        # Utils.deliver new_msg
        # puts "Reminder sent to employer: #{employer.email}"
    # end
    # puts "Review recommended users reminders processed"
  # end  

  task :close_expired_interviews => :environment do
     Interview.close_expired
  end
  
  # sent twice in a week, Monday and Thursday
  task :send_jobs_update_to_engineers => :environment do
    if Time.now.monday? || Time.now.thursday?
       Reminder.send_jobs_update_to_engineers do |invites|
        new_msg = FyiMailer.create_engineer_update_email(invites.first.user, invites)
        Utils.deliver new_msg
      end
    end
  end
  
  # sent every Wednsday, once a week
  task :send_jobs_update_to_employers => :environment do
    if Time.now.wednesday?
      Reminder.send_jobs_update_to_employers do |jobs, just_expired_jobs|
        new_msg = FyiMailer.create_employer_update_email(jobs.first.employer, jobs, just_expired_jobs)
        Utils.deliver new_msg
      end
    end
  end   

  task :send_personal_welcome_message => :environment do
    Reminder.send_personal_welcome_message(Employer) do |employer|
        new_msg = FyiMailer.create_personal_welcome_employer_email(employer)
        Utils.deliver new_msg
        puts "Personal welcome message sent to employer #{employer.email}"
    end
    
    Reminder.send_personal_welcome_message(User) do |user|
        new_msg = FyiMailer.create_personal_welcome_candidate_email(user)
        Utils.deliver new_msg
        puts "Personal welcome message sent to candidate #{user.email}"
    end
    
    puts "All relevant personal welcome messages were sent."
  end
  
  # call it like this: rake cron:send_admin_summary["production"]
  # call it like this: rake cron:send_admin_summary["staging"]
  # call it like this: bundle exec rake cron:send_admin_summary["debug"]
  task :send_admin_summary, [:serv_name] => :environment do |t, args|
    Reminder.send_admin_summary do |events|
      new_msg = FyiMailer.create_admin_summary_email(args[:serv_name], events)
      Utils.deliver new_msg
    end
    
    puts "Admin summary email was sent."
  end
  
  #sent every day to X people until all updated
  task :send_rj_migration_announcement_to_engineers => :environment do
          if Time.now < Time.new(2014,6,30)
           puts "#{Constants::SITENAME} not yet released; not sending migration announcements"
           return
          end
      		count = Reminder.send_rightjoin_migration_announcement_to_engineers do |user|
      		  begin
       				new_msg = FyiMailer.create_rightjoin_migration_announcement_for_candidates_email(user)
				  		Utils.deliver new_msg
            rescue Exception => e
                puts e
            end
       		end
     puts "RJ migration announcements processed" #sent: #{count}."#TODO: THis number always comes out zero 
  end
  
  # send update to employers about new contact
  task :update_employers_about_new_contacts => :environment do
     counter=0
    if !Time.now.sunday? && !Time.now.saturday? 
      count = Reminder.update_employers_about_new_contacts do |employer|
        new_msg = FyiMailer.update_employers_about_new_contacts(employer)
        Utils.deliver new_msg
        counter += 1
      end
      
      puts "New contacts updates sent to employers: #{counter}."
    end
  end
  
  # send updates to ambassador about new contacts
  # Must set cron job to the time shown in Reminder.rb  (8 am Pacific)
    # Not needed because of immediate mailing
  # task :update_ambassador_about_new_contact => :environment do
    # counter=0 
    # today_s =Time.now.utc.strftime("%A")#e.g. "Friday","Tuesday"
    # if Reminder::AMBASSADOR_SEND_DAYS.include?(today_s) 
       # Reminder.update_ambassador_about_new_contact do |infointerview|
          # new_msg = FyiMailer.update_ambassador_about_new_contact(infointerview)
          # Utils.deliver new_msg
          # counter += 1
      # end
#       
      # puts "Emails sent to ambassadors: #{counter}."
    # end
  # end
end
