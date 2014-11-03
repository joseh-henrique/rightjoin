namespace :cron do
  desc "Send reminders"
  
 
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
      Reminder.send_jobs_update_to_employers do |employer,all_jobs, open_jobs, unused_param| 
        new_msg = FyiMailer.create_employer_update_email(employer, all_jobs, open_jobs, unused_param)
        Utils.deliver new_msg
      end
    end
  end   

  task :send_personal_welcome_employer_messages => :environment do
    Reminder.send_personal_welcome_message(Employer) do |employer|
        new_msg = FyiMailer.create_personal_welcome_employer_email(employer)
        Utils.deliver new_msg
        puts "Personal welcome message sent to employer #{employer.email}"
    end
   
    puts "All relevant personal welcome messages  to employers were sent."
  end
  
  task :send_personal_welcome_candidate_messages => :environment do
    
    Reminder.send_personal_welcome_message(User) do |user|
        new_msg = FyiMailer.create_personal_welcome_candidate_email(user)
        Utils.deliver new_msg
        puts "Personal welcome message sent to candidate #{user.email}"
    end
    
    puts "All relevant personal welcome messages to candidates were sent."
  end
  
  # call it like this: rake cron:send_admin_summary["production"]
  #                    rake cron:send_admin_summary["staging"]
  #                    bundle exec rake cron:send_admin_summary["debug"]
  task :send_admin_summary, [:serv_name] => :environment do |t, args|
    Reminder.send_admin_summary do |events|
      new_msg = FyiMailer.create_admin_summary_email(args[:serv_name], events)
      Utils.deliver new_msg
    end
    
    puts "Admin summary email was sent."
  end
  
  task :update_about_new_pings => :environment do
    candidates_counter = 0
    count_not_used1 = Reminder.update_engineers_after_ping do |info_interview|
      new_msg = FyiMailer.update_engineers_after_ping(info_interview)
      Utils.deliver new_msg
      candidates_counter += 1
    end
    puts "After-ping  updates sent to candidates: #{candidates_counter}."

    employers_counter = 0
    count_not_used2 = Reminder.update_employers_about_new_contacts do |employer|
      new_msg = FyiMailer.update_employers_about_new_contacts(employer)
      Utils.deliver new_msg
      employers_counter += 1
    end

    puts "New contacts updates sent to employers: #{employers_counter}."
  end  
  
  # send update to employers about new contact
  task :update_employers_about_new_comments => :environment do
    counter=0
    count = Reminder.update_employers_about_new_comments do |comment|
      new_msg = FyiMailer.update_employer_about_new_comment(comment)
      Utils.deliver new_msg
      counter += 1
    end
    
    puts "New comments updates sent to employers: #{counter}."
  end  
  
  task :send_scheduled_reminders_to_ambassadors => :environment do
    counter = Employer.send_pending_reminders_to_all_ambassadors
    puts "Reminders sent to ambassadors: #{counter}."
  end  
  
  
end
