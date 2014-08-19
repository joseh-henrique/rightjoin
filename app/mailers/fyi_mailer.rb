class FyiMailer < ActionMailer::Base
   
  RJ_CRM_NAME = "Joshua"
  RJ_CRM_FULL_NAME = "Joshua Fox" 
  CRM_SIGNATURE = "All the best,<br><br>
                  #{ RJ_CRM_NAME}"       
  
  
  FYI_FROM = "#{Constants::SHORT_SITENAME} <info@#{Constants::SITENAME_LC}>"
  
  PERSONAL_FROM = "#{RJ_CRM_FULL_NAME} <#{RJ_CRM_NAME.downcase}@#{Constants::SITENAME_LC}>"
  ADMIN_FROM = "Administrator <#{Constants::ADMIN_EMAIL}>"
  
  PLEASE_REPLY = "Questions? Just reply to this message to contact #{Constants::SHORT_SITENAME}."
  
  def create_message(to_email, subj, html_body, text_body, from = FYI_FROM, reply_to = nil )
    result = mail(:to =>to_email, :subject => subj, :from => from, :reply_to => reply_to) do |format|
      format.text { render :text => text_body }
      format.html { render :text => html_body }
    end
  end

  def create_welcome_message(to_email, passwd, locale, reason_to_verify, pg_name, url, intended_for)
    @intended_for = intended_for 
    subj="Activate your #{Constants::SITENAME} profile"

    @msg1_h  = "Welcome to #{Constants::SHORT_SITENAME}. Please verify your account."
    @msg1_t = @msg1_h.clone
     
    country_code = I18n.t(:country_code, :locale => locale)
    msg2_tail = reason_to_verify
    @msg2_h = "Enter your temporary password <strong>#{ERB::Util.html_escape(passwd)}</strong> at the #{Constants::SHORT_SITENAME} <a href=\"#{url}\">#{pg_name}</a> to activate your profile#{msg2_tail}."
    @msg2_t = "Enter your temporary password\n\t\t#{passwd}\nat #{url} to activate your profile#{msg2_tail}."

	  @msg3_h = "You can also sign in at the #{Constants::SHORT_SITENAME} <a href=\"#{url}\">#{pg_name}</a> to activate. "
    @msg3_t = "You can also sign in at #{url} to activate.\n\n"

    html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false

    return create_message to_email, subj, html_body, text_body
  end

  def create_forgot_pw_message(to_email, passwd, get_going_txt, url, intended_for)
    @intended_for = intended_for 
    subj = "Your #{Constants::SHORT_SITENAME} password has been reset"

    msg1 = "You have a new temporary password."
    @msg1_h = msg1.clone
    @msg1_t = msg1.clone

    @msg2_h = "Go ahead and <a href=\"#{url}\">sign in</a> with email address #{ERB::Util.html_escape(to_email)} and your temporary password <b>#{ERB::Util.html_escape(passwd)}</b>"
    @msg2_t = "Go ahead and sign in to #{url}\nwith email address #{to_email}\nand your temporary password #{passwd}"

    @msg3_h = get_going_txt.clone
    @msg3_t = get_going_txt.clone

    html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false

    return create_message to_email, subj, html_body, text_body
  end

  def in_loc(name, escaped_name)
    name == Constants::TELECOMMUTE ? ", working remotely":" in #{escaped_name}"
  end

  def in_loc_h(name)
    in_loc(name,"<b>#{ERB::Util.html_escape(name)}</b>")
  end

  def in_loc_t(name)
    in_loc(name, name)
  end
  
   def call_us_str(locale)
    res = ""
    if locale == Constants::COUNTRIES[Constants::COUNTRY_US]
      res = " Or call us at #{Utils.phone_with_pfx}."
    end
    return res
  end  
  
 
  def create_delegate_infointerview_email(followup)
    @intended_for = :ambassador
    amb = followup.ambassador
    infint= followup.infointerview
    to_email = amb.email
    subj = "Talking to a potential colleague"

    @msg1_h = "Please be in touch with #{ERB::Util.html_escape(infint.full_candidate_name)} on your #{ERB::Util.html_escape(infint.job.company_name)} #{Constants::SHORT_SITENAME} <a href='#{ambassadors_signin_url(infint.employer.reference_num, :locale => nil)}'>team page</a> about the open #{ERB::Util.html_escape(infint.job.position_name)} position." 
    @msg1_t = "Please be in touch with #{infint.full_candidate_name} on your #{infint.job.company_name} #{Constants::SHORT_SITENAME} team page  #{ambassadors_signin_url(infint.employer.reference_num, :locale => nil)} about the open #{infint.job.position_name} position." 
    

    # TODO  use different text if the candidate is referred by this ambassador - followup.infointerview.referred_by == followup.ambassador.id
    @msg2_h = "Follow up with an email, talk on the phone if you'd like, check if you might want to have #{ERB::Util.html_escape(infint.full_candidate_name)} as a colleague. " <<
             "You'll see more details and contact info on the <a href='#{ambassadors_signin_url(infint.employer.reference_num, :locale => nil)}'>team page</a>."
    @msg2_t = "Follow up with an email, talk on the phone if you'd like, check if you might want to have #{infint.full_candidate_name} as a colleague. " << 
             "You'll see more details and contact info on the team page."

    msg3 = "Questions? Just contact #{amb.employer.first_name} #{amb.employer.last_name} at #{amb.employer.email}"
    @msg3_h = msg3.clone
    @msg3_t = msg3.clone

    html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false

    return create_message to_email, subj, html_body, text_body    
  end
  
  def create_engineer_update_email(engineer, invites)
   @intended_for = :employee
   to_email = engineer.email
   
   subj = "Escape-worthy opportunities at #{Constants::SHORT_SITENAME}"
    
   invites_from_registered_employers = invites.reject{|invite| invite.job.from_fyi}
       
   if invites_from_registered_employers.length > 0
      sing = invites_from_registered_employers.length == 1
      @msg1_h = sing ? "The dev team from #{invites_from_registered_employers[0].job.company_name} wants to be in touch." : "Dev teams want to be in touch."
    else # All jobs from FYI itself
       @msg1_h = "We've got a good job match for you."
    end
    
    contact_amb_s = Interview.have_active_ambassadors?(invites) ? ", and to chat with insiders" : ""
    msg1_tail = " You're invited to talk directly to them#{contact_amb_s}."
    @msg1_h << msg1_tail
    
    @msg1_t = @msg1_h.gsub("<br>", "\n")
    
    @msg2_h = "Sign in to see all the info at your #{Constants::SHORT_SITENAME} <a href='#{user_url(engineer, :locale => engineer.country_code)}'>dashboard</a>.<br><br>"
    @msg2_t = Utils.html_email_to_txt(@msg2_h) 
     
    invites.each do |interview|
        raise "Expect only APPROVED invitations here, but found: #{interview}" unless interview.status == Interview::APPROVED
        
        truncated_job_desc = Utils.truncate(Utils.html_to_formatted_plaintext(interview.job.full_description), Job::SHORT_DESCRIPTION_LEN)
        @msg2_h << "<b>#{interview.job.position.name}</b> at <b>#{ERB::Util.html_escape(interview.job.company_name)}</b><br>
                          <div style='background:#f8f8f8; padding:10px;'>#{truncated_job_desc}</div><br>"
        @msg2_t << "#{interview.job.position.name} at #{interview.job.company_name}\n
                       #{truncated_job_desc}\n\n"
    end
    
    msg3_head ="You can always find your recent pings from employers on your #{Constants::SHORT_SITENAME}" 
    msg3_tail ="#{PLEASE_REPLY}#{call_us_str(engineer.locale)}"
    @msg3_h = "#{msg3_head} <a href='#{user_url(engineer, :locale => engineer.country_code)}'>dashboard</a>.<br>#{msg3_tail}"
    @msg3_t = "#{msg3_head} dashboard (#{user_url(engineer, :locale => engineer.country_code)}). \n#{msg3_tail}"
   
    msg_footer_tail =  "(You can reactivate later.)"
    @msg_footer_h = "Not interested anymore? <a href='#{unsubscribe_user_url(:locale => I18n.t(:country_code, engineer.locale), :id => engineer.id, :ref => engineer.reference_num(true))}'>Click here</a> to deactivate your account. #{msg_footer_tail}"
    @msg_footer_t = "Not interested anymore? Go to this URL to deactivate your account:\n#{unsubscribe_user_url(:locale => I18n.t(:country_code, engineer.locale), :id => engineer.id, :ref => engineer.reference_num(true))}\n#{msg_footer_tail}"

    html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false
 
    return create_message to_email, subj, html_body, text_body    
  end
  
  #TODO all_jobs and open_jobs are the same now. So, remove open_jobs param. And remove unused_param
  def create_employer_update_email(employer, all_jobs, open_jobs, unused_param) 
       @intended_for = :employer
       
       to_email = employer.email
       subj = "What's happening with your ads at #{Constants::SHORT_SITENAME}."
       todays_day = Time.now.strftime('%A')
        
       @msg1_h =  "It's #{todays_day}. Time to let you know what's been going on with your job postings in the last week."
       @msg1_t = @msg1_h
      
       @msg2_h = ""
       @msg2_t = ""
      
       # recommendations go first
       recommended_candidates_count = employer.interviews.where(status: Interview::RECOMMENDED).count
       if recommended_candidates_count > 0
          rec_line_head = "We've recommended new candidates for you. "
          rec_line_tail = "and invite them to be in touch." 
          rec_line_h= "#{rec_line_head} <a href=\"#{employer_welcome_url}\">Take a look</a>,   #{rec_line_tail}<br><br>"  
          rec_line_t= "#{rec_line_head} Take a look, #{rec_line_tail}<br><br>"  
           
          @msg2_h << rec_line_h
          @msg2_t << rec_line_t.gsub("<br>", "\n")  
       end
     
       # list open jobs
       if open_jobs.empty?          
          no_jobs_no_charge_s = "You have no open job positions. (You won't be charged for any month in which you had no open positions.)<br><br>"
          @msg2_h <<  no_jobs_no_charge_s
          @msg2_t <<  no_jobs_no_charge_s.gsub("<br>", "\n")
       else
          stats_s = "Your open job postings:<br><br>"
          @msg2_h << stats_s 
          @msg2_t << stats_s.gsub("<br>", "\n")
        
          open_jobs.each_with_index do |job, index|
            bullet = all_jobs.count > 1 ? "#{index + 1})" : ""
            @msg2_h <<  "#{bullet} <b>#{job.position.name}</b>#{in_loc_h(job.location.name)}"
            @msg2_t <<  "#{bullet} #{job.position.name}#{in_loc_t(job.location.name)}"
            boards= job.ads.map { |ad| ad.board.title }
            if boards.empty?
                @msg2_h  << "<br><br>"  
                @msg2_t  << "\n\n"
            else
                board_list_s = "&nbsp;is listed under #{ boards.map {|board| "%{styleopen}#{board}%{styleclose}"}.to_sentence}.<br><br>" 
                @msg2_h << board_list_s % {:styleopen => "<b>", :styleclose => "</b>"} 
                @msg2_t << (board_list_s % {:styleopen => "", :styleclose => ""}).gsub("<br>", "\n").gsub("&nbsp;","\t")
            end
        end            
     end
      

       
      
      # counters 
      total_invites_counter = all_jobs.inject(0){|sum,job| sum + job.invites_counter} 
      counters_s =""
      if all_jobs.any? && total_invites_counter == 0
        counters_s<< "To bring in some good candidates, you can ping developers on the Stealth Candidates board, and ask them to be in touch.<br>"
      end
      
      if employer.ambassadors.empty?
        counters_s << "<br>To increase referral hires, invite team members to share open positions with their social networks.<br>"  
      end
      
      shared_counter = all_jobs.inject(0){|sum,job| sum + job.shares_counter.to_i} 
      counters_s << "<br> Shares: #{shared_counter}"  
      
      clickback_counter = all_jobs.inject(0){|sum,job| sum + job.clickback_counter.to_i} 
      counters_s << "<br> Impressions: #{clickback_counter}"  
      
      # need to count infointerviews as not all leads come from shares
      leads_count = all_jobs.inject(0){|sum,job| sum + job.all_generated_leads_count.to_i} 
      counters_s << "<br> Leads: #{leads_count}<br>" 
 
      @msg2_h << counters_s  
      @msg2_t << counters_s.gsub("<br>","\n").gsub("&nbsp;","\t")
      
     
      msg3_head = "Manage your campaign at your #{Constants::SHORT_SITENAME} "
      @msg3_h = "#{msg3_head} <a href='#{employer_url(employer, :locale => all_jobs.first.country_code)}'>dashboard</a>.<br><br>"
      @msg3_t = "#{msg3_head} dashboard: #{employer_url(employer, :locale => all_jobs.first.country_code)}\n\n"
      
      reply_s =  PLEASE_REPLY
      @msg3_h << reply_s
      @msg3_t << reply_s  
      
       
      @msg_footer_h = employer_unsubscribe_link(true, employer) 
      @msg_footer_t = employer_unsubscribe_link(false, employer)

      html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
      text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false
      
      return create_message to_email, subj, html_body, text_body   
  end

 
  def create_rightjoin_migration_announcement_for_candidates_email(candidate) 
      @intended_for = :employee
      
      to_email = candidate.email
      subject = "#{Constants::FIVEYEARITCH_SHORT_SITENAME} is now #{Constants::SHORT_SITENAME}"
     
      fn = candidate.first_name.blank? ? ""  : (candidate.first_name + ", ")
      
      salutation =  "Hi, #{fn}it's #{RJ_CRM_NAME} from #{Constants::FIVEYEARITCH_SHORT_SITENAME}." 
   
       content =
          "It's been a while since you've heard from us. We didn't want to bother you. But now, after a lot of discussions with developers, we've come up with a new way to get them into better jobs.<br><br>"<<
          "We're pivoting to \"peer-to-peer\" recruiting: We help developers outside a company connect with developers inside it for a chat, bypassing recruiters and HR.<br><br>" << 
          "A new direction needs a new name. So, we're moving from #{Constants::FIVEYEARITCH_SITENAME} to #{Constants::SITENAME}. " << 
          "The new #{Constants::SITENAME} is in closed beta, but as a long-term member you can still sign in at <a href='#{user_url(candidate, :locale => candidate.country_code)}'>your profile</a>.<br><br>" << 
          "If you have any questions, just hit Reply.<br>"
   
      signature = "" + CRM_SIGNATURE
      signature << "<br><br><br>P.S. Not interested anymore?  " << 
          "<a href='#{unsubscribe_user_url(:locale => I18n.t(:country_code, candidate.locale), :id => candidate.id, :ref => candidate.reference_num(true))}'>Click here</a> to deactivate your account. (You can reactivate later.)"
     
       
      return create_simple_text_email(subject, salutation, content, signature, to_email, PERSONAL_FROM)
  end


  


  def create_personal_welcome_candidate_email(user)
    subject = "Welcome to #{Constants::SHORT_SITENAME} "

    salutation = user.first_name.blank? ? "Welcome" : "Hi, #{user.first_name}, welcome" # TODO escape name. But email clients strip script tags, so this is not too bad
    salutation<<" to #{Constants::SHORT_SITENAME}."

    content =
      "I'm #{RJ_CRM_NAME}, co-founder at  #{Constants::SHORT_SITENAME}. I'm writing to tell you what comes next.<br><br>" <<
      "Employers can review your anonymous #{Constants::SHORT_SITENAME} profile and invite you to be in touch. " <<
      "We keep you spam-free by letting employers ping you only when they have jobs that meet your requirements; we  screen  each invitation.<br><br>" <<
      "Go ahead and browse the specialized job listings, and ping the employers who interest you.<br><br>" <<
      "Share #{Constants::SHORT_SITENAME} using the buttons at the footer of each page to help us launch the peer-to-peer recruiting revolution.<br><br>" <<
      "And don't hesitate to contact me with any questions.<br>"

    signature ="" + CRM_SIGNATURE

    return create_simple_text_email(subject, salutation, content, signature, user.email, PERSONAL_FROM)
  end



  def create_personal_welcome_employer_email(employer)
    subject = "Welcome to #{Constants::SHORT_SITENAME}"

    salutation = "Hi, #{employer.first_name}, welcome to #{Constants::SHORT_SITENAME}."# TODO escape name. But email clients strip script tags, so this is not too bad

    content = "I'm #{RJ_CRM_NAME}, co-founder of #{Constants::SHORT_SITENAME}. "

    if employer.jobs.blank? || employer.ambassadors.blank?
      please_add_template =  "Please go ahead and add some %s. Feel free to shoot me an email if you have any questions on how to do that.<br><br>"
      to_add = []
      to_add << "job postings"  if employer.jobs.blank?
      to_add << "team members" if employer.ambassadors.blank?   
      please_add_s = please_add_template % to_add.to_sentence
      content << please_add_s
    elsif  
      content<< "I'm writing to tell you what comes next.<br><br>"
    end
     
    content << "We've designed a posting that your team will  want to share, one that puts them in the center. You can point your team members at the social sharing tools, designed for peer-to-peer recruiting<br><br>" <<
        "You can add the geotargeted \"Join Us\" tab to the #{employer.company_name} site for software developers who are curious about your company.<br><br>" <<
        "You can track progress on your profile page, and we'll send you brief weekly summaries. " <<
        "In the meantime, don't hesitate to contact me--I want to know how #{Constants::SHORT_SITENAME} can help you reach out to strong developers.<br>"

    signature = ""+CRM_SIGNATURE

    return create_simple_text_email(subject, salutation, content, signature, employer.email, PERSONAL_FROM)
  end

  def create_admin_summary_email(server_name, events)
    def dump_object_array(title, objs)
      res = ""
      unless objs.blank?
        res << "\n============= #{title} =============\n"
        objs.each do |o|
          if o.nil?
            res << "==> Error reporting event: object not found"
          else
          res << o.inspect
          end
          res << "\n"
        end
      end
      return res
    end

    new_candidates = events.select {|e| e.reminder_type == Reminder::USER_ACCOUNT_ACTIVATED.to_s}
    new_employers = events.select {|e| e.reminder_type == Reminder::EMPLOYER_ACCOUNT_ACTIVATED.to_s}
    created_jobs = events.select {|e| e.reminder_type == Reminder::JOB_CREATED.to_s}
    companies_rated = events.select {|e| e.reminder_type == Reminder::COMPANY_RATED_ACTION.to_s}
    new_leads = events.select {|e| e.reminder_type == Reminder::NEW_LEAD.to_s}
    invites_to_approve = Interview.where("status = #{Interview::AWAITING_APPROVAL}")
    events_count = new_candidates.count + new_employers.count + created_jobs.count + companies_rated.count + invites_to_approve.count + invites_to_approve.count + new_leads.count

    text = ">>>>>> Activity report - #{server_name} - #{Date.today} <<<<<<\n"
    text << "No new events for the past day.\n" if events_count == 0
    
    total_users = User.count(:conditions => ["status = ? and sample is not TRUE", UserConstants::VERIFIED])
    total_employers = Employer.count(:conditions => ["status = ? and sample is not TRUE", UserConstants::VERIFIED])
    total_draft_jobs = Job.count(:conditions => ["status = ?", Job::DRAFT])
    total_published_jobs = Job.count(:conditions => ["status = ?", Job::PUBLISHED])
    total_infointerviews = Infointerview.count()
    total_invites = Job.sum("invites_counter")
    
    text << "\n\n>>>>>>>>>>>>>>>> Statistics <<<<<<<<<<<<<<<<<\n"
    text << "Users count: #{total_users}\n"
    text << "Employers count: #{total_employers}\n"
    text << "Job drafts count: #{total_draft_jobs}\n"
    text << "Published jobs count: #{total_published_jobs}\n"
    text << "Infointerviews count: #{total_infointerviews}\n"
    text << "Invitations count: #{total_invites}\n"

    text << dump_object_array("New candidate signups", new_candidates.map{|e| User.find(e.linked_object_id)})
    text << dump_object_array("New employer signups", new_employers.map{|e| Employer.find(e.linked_object_id)})
    text << dump_object_array("New opened jobs", created_jobs.map{|e| Job.find(e.linked_object_id)})
    text << dump_object_array("New leads", new_leads.map{|e| Infointerview.find(e.linked_object_id)})    
    text << dump_object_array("Companies rated", companies_rated.map{|e| CompanyRating.find(e.linked_object_id)})

    if invites_to_approve.any?
      text << "\n\n>>>>>>>>>>>>>>>> Invitations awaiting approval: #{invites_to_approve.count} <<<<<<<<<<<<<<<<<\n"
      invites_to_approve.each do |invite|
        text << invite.inspect
        text << "\n"
      end
    end 

    return create_message Constants::ADMIN_EMAIL, "Daily summary", text.gsub("\n", "<br>"), text, ADMIN_FROM
  end
  
   def employer_unsubscribe_link(is_html, employer )
      jobs = employer.jobs  
      country_code = jobs.first.country_code unless jobs.empty?  #can end up null
      
      if is_html
          return "Not hiring anymore? <a href='#{unsubscribe_employer_url(:id => employer.id, :ref => employer.reference_num(true))}'>Click here</a> to close all job postings and unsubscribe."
      else 
          return "Not hiring anymore? Go to this URL to to close all job postings and unsubscribe:\n#{unsubscribe_employer_url(:id => employer.id, :ref => employer.reference_num(true))}\n"
      end
  end
   
 
  def update_employers_about_new_contacts(employer)
    @intended_for = :employer
    contact_count = employer.contacts_count.to_i
 
    subject = "Ping#{(contact_count == 1)? "" : "s"} from developers: For your review"
      
    if contact_count == 1
       dev_s = "a developer is"
    else   
       dev_s =  "#{contact_count} developers are"
    end 
    
    @msg1_h = "Hi, #{employer.first_name}, #{dev_s} pinging you and your team."
    @msg1_t = Utils.html_email_to_txt(@msg1_h)
    
 
    @msg2_h = "Please review the candidate#{(contact_count == 1)? "'s" : "s'"} information and decide whether to  put a team member in touch, at your <a href='#{employer_url(employer, :locale => nil, :need_approvals=>true)}'>#{Constants::SHORT_SITENAME} dashboard</a>."  
    @msg2_t = Utils.html_email_to_txt(@msg2_h)
    
     
    @msg3_h = PLEASE_REPLY
    @msg3_t = @msg3_h.clone
    
    @msg_footer_h = employer_unsubscribe_link(true, employer) 
    @msg_footer_t = employer_unsubscribe_link(false, employer)

    html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false
 
    return create_message employer.email, subject, html_body, text_body       
  end
 
  # one comment - one email
  def update_employer_about_new_comment(comment) # only from ambassadors to employers
    @intended_for = :employer
    
    employer = comment.infointerview.employer
    ambassador = comment.ambassador
    infointerview = comment.infointerview
    path = leads_employer_job_url(employer, infointerview.job, :locale => infointerview.job.country_code, anchor: "lead-#{infointerview.id}")
    
    subject = "New comment on candidate"
    
    @msg1_h = "Hi, #{ambassador.full_name} added a comment about #{infointerview.full_candidate_name}."
    @msg1_t = Utils.html_email_to_txt(@msg1_h)
 
    @msg2_h = "Please <a href='#{path}'>review the comment</a> and decide whether to ask someone else in your team to talk with this candidate or to contact the candidate yourself."  
    @msg2_t = Utils.html_email_to_txt(@msg2_h)
    
    @msg3_h = PLEASE_REPLY
    @msg3_t = @msg3_h.clone
    
    @msg_footer_h = employer_unsubscribe_link(true, employer) 
    @msg_footer_t = employer_unsubscribe_link(false, employer)

    html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false
 
    return create_message employer.email, subject, html_body, text_body       
  end 
 
  def create_ambassador_profile_updated_email(ambassador)
    @intended_for = :employer
    subject = "#{ambassador.first_name} has signed up to talk to professional peers"
     
    @msg1_h = "#{ERB::Util.html_escape(ambassador.first_name)} #{ERB::Util.html_escape(ambassador.last_name)} has joined the #{ERB::Util.html_escape(ambassador.employer.company_name)} team." 
    @msg1_t = "#{ambassador.first_name} #{ambassador.last_name} has joined the #{ambassador.employer.company_name} team." 
    
    @msg2_h = "Track progress on your <a href='#{employer_url(ambassador.employer, :locale => nil, :anchor=>"ambassadors" )}'>#{Constants::SHORT_SITENAME} dashboard</a>.<br><br>" << 
            "Reach out to qualified software engineers by adding the \"Come Work With Us\" tab  to the #{ERB::Util.html_escape(ambassador.employer.company_name)} corporate site, " << 
            "and by referring more team members to the social sharing tools."
    @msg2_t = Utils.html_email_to_txt(@msg2_h)

    @msg3_h = PLEASE_REPLY 
    @msg3_t = Utils.html_email_to_txt(@msg3_h)
    
    @msg_footer_h = employer_unsubscribe_link(true, ambassador.employer)
    @msg_footer_t = employer_unsubscribe_link(false, ambassador.employer)
    
    html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false
 
    return create_message ambassador.employer.email, subject, html_body, text_body       
  end
  
  def create_ambassador_reminder_message(ambassador, subject, body)
    body = body.gsub("[first-name]", ambassador.first_name).gsub("[team-page-url]", ambassadors_signin_url(ambassador.employer.reference_num, :locale => nil))
    new_msg = create_message(ambassador.email, subject, body.gsub("\n", "<br>"), body)
  end

  private

  def create_simple_text_email(subject, salutation, content, signature, to_email, sender)
    @msg_salutation = salutation
    @msg_content = content
    @msg_signature = signature
   
    html_body = render_to_string 'fyi_mailer/create_personal_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_personal_message', :formats => [:text], :handlers => [:erb], :layout => false
    # See also Utils.html_email_to_txt for another way of converting HTML to txt, here and above.
    text_body = text_body.gsub("&nbsp;", " ")
    text_body = text_body.gsub("<br>", "\n")
    text_body = text_body.gsub("<hr>", "________________________________________")
    text_body = text_body.gsub(/<a\s+href\s*=\s*["'](.+?)["']>(.+?)<\/a>/, "\\2 ( \\1 )")

    return create_message(to_email, subject, html_body, text_body, sender)
  end
end

