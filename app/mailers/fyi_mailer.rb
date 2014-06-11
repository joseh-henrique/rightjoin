class FyiMailer < ActionMailer::Base
  FYI_FROM = "#{Constants::SHORT_SITENAME} <#{Constants::SHORT_SITENAME.downcase}@#{Constants::SITENAME_LC}>"
  PERSONAL_FROM = "#{Constants::FYI_CRM_NAME} <#{Constants::FYI_CRM_NAME.downcase}@#{Constants::SITENAME_LC}>"
  ADMIN_FROM = "Administrator <#{Constants::ADMIN_EMAIL}>"

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
    @msg2_h = "Enter your password <strong>#{ERB::Util.html_escape(passwd)}</strong> at the #{Constants::SHORT_SITENAME} <a href=\"#{url}\">#{pg_name}</a> to activate your profile#{msg2_tail}."
    @msg2_t = "Enter your password\n\t\t#{passwd}\nat #{url} to activate your profile#{msg2_tail}."

    @msg3_h = "You can also sign in at the #{Constants::SHORT_SITENAME} <a href=\"#{url}\">#{pg_name}</a> at any time with your email address <em>#{ERB::Util.html_escape(to_email)}</em> and your password <strong>#{ERB::Util.html_escape(passwd)}</strong>"
    @msg3_t = "You can also sign in at #{url} at any time\nwith your email address #{to_email} and your password #{passwd}\n\n"

    html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false

    return create_message to_email, subj, html_body, text_body
  end

  def create_forgot_pw_message(to_email, passwd, get_going_txt, url, intended_for)
    @intended_for = intended_for 
    subj = "Your #{Constants::SHORT_SITENAME} password has been reset"

    msg1 = "Your password has been changed!"
    @msg1_h = msg1.clone
    @msg1_t = msg1.clone

    @msg2_h = "Go ahead and <a href=\"#{url}\">sign in</a> with email address #{ERB::Util.html_escape(to_email)} and your new password <b>#{ERB::Util.html_escape(passwd)}</b>"
    @msg2_t = "Go ahead and sign in to #{url}\nwith email address #{to_email}\nand your new password #{passwd}"

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
  
  def create_engineer_update_email(engineer, invites)
   @intended_for = :employee
   to_email = engineer.email
   
   subj = "Escape-worthy opportunities at #{Constants::SHORT_SITENAME}"
    
   invites_from_registered_employers = invites.reject{|invite| invite.job.from_fyi}
       
   if invites_from_registered_employers.length > 0
      sing = invites_from_registered_employers.length == 1
      @msg1_h = sing ? "An employer wants to talk" : "Employers want to talk"
    else # All jobs from FYI itself
       @msg1_h = "We've got a good job match for you."
    end
 
    @msg1_t = @msg1_h.gsub("<br>", "\n")
    
    contact_amb_s = Interview.have_active_ambassadors?(invites) ? ", and to chat with insiders" : ""
 
    msg2_start = "You're invited to contact them#{contact_amb_s}.<br><br>"
    @msg2_h = msg2_start 
    @msg2_t = Utils.html_to_txt(msg2_start)
    
    invites.each do |interview|
        raise "Expect only APPROVED invitations here, but found: #{interview}" unless interview.status == Interview::APPROVED
        
        truncated_job_desc = Utils.truncated_plaintext(interview.job.description, :length => 250).html_safe
        @msg2_h << "<b><a href='#{interview.job.ad_url}' target='_blank'>#{interview.job.position.name} at #{interview.job.company_name}</a></b><br>
                          <div style='background:#f8f8f8; padding:10px;'>#{truncated_job_desc}</div><br>"
        @msg2_t << "#{interview.job.position.name} at #{interview.job.company_name} (#{interview.job.ad_url})\n
                       #{truncated_job_desc}\n\n"
       
    end
    
    msg3_head ="You can always find your recent invitations on your #{Constants::SHORT_SITENAME}" 
    msg3_tail="Any questions? Just reply to this email#{Utils::call_us_str(engineer.locale)}.""
    @msg3_h = "#{msg3_head} <a href='#{user_url(engineer, :locale => engineer.country_code)}'>home page</a>.<br>#{msg3_tail}"
    @msg3_t = "#{msg3_head} home page (#{user_url(engineer, :locale => engineer.country_code)}). \n#{msg3_tail}"
    msg_footer_tail =  "(You can reactivate later.)"
    @msg_footer_h = "Not interested anymore? <a href='#{unsubscribe_user_url(:locale => I18n.t(:country_code, engineer.locale), :id => engineer.id, :ref => engineer.reference_num(true))}'>Click here</a> to deactivate your account. #{msg_footer_tail}"
    @msg_footer_t = "Not interested anymore? Go to this URL to deactivate your account:\n#{unsubscribe_user_url(:locale => I18n.t(:country_code, engineer.locale), :id => engineer.id, :ref => engineer.reference_num(true))}\n#{msg_footer_tail}"

    html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false
 
    return create_message to_email, subj, html_body, text_body    
  end
  
  
  def create_employer_update_email(employer, all_jobs, open_jobs, just_expired_jobs)
       @intended_for = :employer
       
       to_email = employer.email
       subj = "Here's what's happening with your social job ads at #{Constants::SHORT_SITENAME}."
       todays_day = Time.now.strftime('%A')
        
       @msg1_h =  "It's #{todays_day}. Time to let you know what's been going on with your job postings in the last week."
       @msg1_t = @msg1_h
      
       @msg2_h = ""
       @msg2_t = ""
      
       # recommendations go first
       recommended_candidates_count = employer.interviews.where(status: Interview::RECOMMENDED).count
       if recommended_candidates_count > 0
          job_noun = jobs_with_approved_recommendations.size<=1 ? "this job":"these jobs"   
          rec_line_head = "We've recommended #{pluralize(recommended_candidates_count, 'new candidate')} to you. "
          rec_line_tail = "and invite them to be in touch." 
          rec_line_h= "#{rec_line_head} <a href=\"#{employer_welcome_url}\">Take a look</a>, and #{rec_line_tail}.<br><br>"  
          rec_line_t= "#{rec_line_head} Take a look, #{rec_line_tail}<br><br>"  
           
          @msg2_h << rec_line_h
          @msg2_t << rec_line_t.gsub("<br>", "\n")  
       end
     
       # list open jobs
       if open_jobs.empty?
         if employer.current_plan.tier > Constants::TIER_FREE
            premium_no_jobs_s = "You have a premium plan but no open job positions. If you'd like to freeze your account, you can simply revert to a free plan at anytime.<br><br>"
            @msg2_h <<  premium_no_jobs_s
            @msg2_t <<  premium_no_jobs_s.gsub("<br>", "\n")
         end
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
              no_boards_s = "&nbsp;isn't included in the listings at #{Constants::SITENAME}.
                              You can still search our listings and invite candidates to apply.<br><br>"
                   
              @msg2_h  << no_boards_s  
              @msg2_t  << no_boards_s.gsub("<br>", "\n").gsub( "&nbsp;","\t")
          else
              board_list_s = "&nbsp;is listed under #{ boards.map {|board| "%{styleopen}#{board}%{styleclose}"}.to_sentence}.<br><br>" 
              @msg2_h << board_list_s % {:styleopen => "<b>", :styleclose => "</b>"} 
              @msg2_t << (board_list_s % {:styleopen => "", :styleclose => ""}).gsub("<br>", "\n").gsub("&nbsp;","\t")
          end
        end            
     end
      

      unless just_expired_jobs.empty?
          recently_closed_s = "Recently expired postings<br><br>"
          bullet = "\u2022".encode('utf-8')
          
          @msg2_h << recently_closed_s 
          @msg2_t << recently_closed_s.gsub("<br>","\n") 
    
          just_expired_jobs.each do |job|
              @msg2_h << "#{bullet}&nbsp;<b>#{job.position.name}</b>#{in_loc_h(job.location.name)}<br>"
              @msg2_t << "#{bullet} #{job.position.name}#{in_loc_t(job.location.name)}\n"
          end
          
          reopen = "<br>With the free plan, ads are removed from  #{Constants::SITENAME} after a month, " +
            "though they continue  in the web component accessed through a tab on your site until you close them. " + 
            "If you'd like a job posting to continue in our listings after it has expired, please re-post it.<br><br>"
        
          @msg2_h << reopen
          @msg2_t << reopen.gsub("<br>","\n") 
      end
      
      # Asking them to invite candidates is a distraction 
      # # counters 
      # total_invites_counter = all_jobs.inject(0){|sum,job| sum + job.invites_counter} 
      # counters_s =""
      # if all_jobs.any? && total_invites_counter == 0
        # counters_s<< "You have not invited any candidates yet. Go ahead and invite some to apply to your jobs or speak to your employees.<br>"
      # end
      
      if employer.ambassadors.empty?
        counters_s << "<br> Invite team members to share open positions with their social networks.<br>"  
      end
      
      shared_counter = all_jobs.inject(0){|sum,job| sum + job.shares_counter.to_i} 
      counters_s << "<br> Shares: #{shared_counter}"  
      
      clickback_counter = all_jobs.inject(0){|sum,job| sum + job.clickback_counter.to_i} 
      counters_s << "<br> Clickbacks: #{clickback_counter}"  
      
      # need to count infointerviews as not all leads come from shares
      leads_count = all_jobs.inject(0){|sum,job| sum + job.all_generated_leads_count.to_i} 
      counters_s << "<br> Leads: #{leads_count}<br>" 
 
      @msg2_h << counters_s  
      @msg2_t << counters_s.gsub("<br>","\n").gsub("&nbsp;","\t")
      
     
      msg3_head = "Manage your campaign at your #{Constants::SHORT_SITENAME} "
      @msg3_h = "#{msg3_head} <a href='#{employer_url(employer, :locale => all_jobs.first.country_code)}'>home page</a>.<br><br>"
      @msg3_t = "#{msg3_head} home page: #{employer_url(employer, :locale => all_jobs.first.country_code)}\n\n"
      
      reply_s = "Any questions? Just reply to this email or call us at #{Utils.phone_with_pfx}."
      @msg3_h << reply_s
      @msg3_t << reply_s  
      
       
      @msg_footer_h = employer_unsubscribe_link(true, employer) 
      @msg_footer_t = employer_unsubscribe_link(false, employer)

      html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
      text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false
      
      return create_message to_email, subj, html_body, text_body   
  end

  #TODO Delete this method?
  def create_amb_service_announcement_email(candidate)
    @intended_for = :employee
    to_email = candidate.email
    subj = "#{Constants::SHORT_SITENAME}'s latest"
 
    @msg1_h = "Ever wondered what it's like to work at another company?"
    @msg1_t = Utils.html_to_txt @msg1_h 
     
    pfx = candidate.first_name.blank? ? "" : "Hey #{candidate.first_name},<br><br>"   
 
    @msg2_h = pfx+
      "You may have seen the quizzes on #{Constants::SHORT_SITENAME}. 
      They reveal some pretty interesting <a href='#{findings_url(:locale => I18n.t(:country_code, candidate.locale))}'>results</a>,
      and sometimes they send us off to heads-down coding for weeks on end.<br><br>
      That's what happened when 235 developers told us that they want to talk directly to their peers in the hiring companies.<br><br>
      So today we're excited to announce our new feature: \"Developers recruiting developers.\"<br><br>
      Click on the profile of a company insider and ask  \"What's it like to work there? Does it match the hype? Is there
      really a <a href='http://pando.com/2013/12/21/in-praise-of-the-office-kegerator-the-future-of-better-jobs/'>kegerator</a>?\" \u263A<br><br> 
      We see this as  networking done right. Maybe you (like us) think that networking's great when it involves TCP packets, but when it involves meet-and-greet, we have better things to do. 
      This feature makes it easy: It puts you right in touch with a fellow developer at an interesting company who wants to be contacted. <br><br> 
      Our beta is just launching now: Take a look at the first few \"ambassadors\" at <a href='#{jobs_url(:locale => I18n.t(:country_code, candidate.locale))}'>#{Constants::SHORT_SITENAME}</a>.
      If they look like the sort of person you might want to work with, click and ask them what their job is like.<br><br>  
      Best,<br><br>
      #{Constants::FYI_CRM_NAME}"

    @msg2_t = Utils.html_to_txt @msg2_h

    @msg3_h = "And one more thing: If you'd  like to find better colleagues to work with, let us know; 
         We're looking for employers as beta customers. We want to do what it takes to make you happy."
           
    @msg3_t = Utils.html_to_txt @msg3_h
    
    @msg_footer_h = "Not interested anymore? <a href='#{unsubscribe_user_url(:locale => I18n.t(:country_code, candidate.locale), :id => candidate.id, :ref => candidate.reference_num(true))}'>Click here</a> to deactivate your account. (You can reactivate later.)"
    @msg_footer_t = "Not interested anymore? Go to this URL to deactivate your account:\n#{unsubscribe_user_url(:locale => I18n.t(:country_code, candidate.locale), :id => candidate.id, :ref => candidate.reference_num(true))}\n(You can reactivate later.)"

    html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false
 
    return create_message to_email, subj, html_body, text_body       
  end


  CRM_SIGNATURE = "Best,<br><br>
                  #{Constants::FYI_CRM_NAME}"


  def create_personal_welcome_candidate_email(user)
    subject = "Welcome to #{Constants::SHORT_SITENAME} "

    salutation = user.first_name.blank? ? "Welcome" : "Hi, #{user.first_name}, welcome"
    salutation<<" to #{Constants::SHORT_SITENAME}."

    content =
      "I'm #{Constants::FYI_CRM_NAME}, your contact at #{Constants::SHORT_SITENAME}. I'm writing to tell you what comes next.<br><br>" <<
      "Employers can review your anonymous #{Constants::SHORT_SITENAME} profile and invite you to apply to jobs.<br><br>" <<
      "We keep you spam-free by letting employers invite you only to jobs that meet your requirements; we  screen  each invitation.<br><br>" <<
      "Go ahead and browse the specialized job listings and ping the employers who interest you.<br><br>" <<
      "And don't hesitate to contact me with any questions.<br>"

    signature =""+CRM_SIGNATURE

    return create_simple_text_email(subject, salutation, content, signature, user.email,PERSONAL_FROM)
  end



  def create_personal_welcome_employer_email(employer)
    subject = "Welcome to #{Constants::SHORT_SITENAME}"

    salutation = "Hi, #{employer.first_name}, welcome to #{Constants::SHORT_SITENAME}."

    content = "I'm #{Constants::FYI_CRM_NAME}, your contact  at #{Constants::SHORT_SITENAME}. "

    if employer.jobs.blank? || employer.ambassadors.blank?
      please_add_template =  "Please go ahead and add some %s. Feel free to shoot me an email if you have any questions on how to do that.<br><br>"
      to_add = []
      to_add << "job postings"  if employer.jobs.blank?
      to_add << "employees to represent you to their colleagues" if employer.ambassadors.blank?   
      please_add_s = please_add_template % to_add.to_sentence
      content << please_add_s
    elsif  
      content<< "I'm writing to tell you what comes next.<br><br>"
    end
     
    content << "Ask your employees to share our ad using the tools at #{Constants::SHORT_SITENAME}: We've designed a posting that they'll want to share, one that puts them in the center.<br><br>" <<
        "Add the geotargeted tab to the #{ employer.company_name}  site.<br><br>" <<
        "You can track progress on your profile page, and we'll send you brief weekly summaries. " <<
        "In the meantime, don't hesitate to contact me--I want to know how #{Constants::SHORT_SITENAME} can help you reach out to  more strong developers.<br>"

    signature = ""+CRM_SIGNATURE

    return create_simple_text_email(subject, salutation, content, signature, employer.email,PERSONAL_FROM)
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
    total_jobs = Job.count(:conditions => ["status = ?", Job::LIVE])
    total_infointerviews = Infointerview.count()
    total_invites = Job.sum("invites_counter")
    
    text << "\n\n>>>>>>>>>>>>>>>> Statistics <<<<<<<<<<<<<<<<<\n"
    text << "Users count: #{total_users}\n"
    text << "Employers count: #{total_employers}\n"
    text << "Jobs count: #{total_jobs}\n"
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
       dev_s = "a developer is "
    else   
       dev_s =  "#{contact_count} developers are "
    end 
    
    @msg1_h = "Hi, #{employer.first_name}, #{dev_s} pinging you and your team."
      @msg1_t = Utils.html_to_txt(@msg1_h)
    
 
    @msg2_h = "Please review the candidate#{(contact_count == 1)? "'s" : "s'"} information and decide whether to  put a team member in touch at on your <a href='#{employer_url(employer, :locale => nil, :need_approvals=>true)}'>#{Constants::SHORT_SITENAME} home page</a>."  
    @msg2_t = Utils.html_to_txt(@msg2_h)
    
     
    @msg3_h = "We believe that peer-to-peer recruiting is the best way to bring in strong professionals. Please let us know if you have any questions."
    @msg3_t = Utils.html_to_txt(@msg3_h )
    
    @msg_footer_h = employer_unsubscribe_link(true, employer) 
    @msg_footer_t = employer_unsubscribe_link(false, employer)

    html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false
 
    return create_message employer.email, subject, html_body, text_body       
  end
 
 
  def create_ambassador_profile_updated_email(ambassador)
    @intended_for = :employer
    subject = "#{ambassador.first_name} has signed up to talk to professional peers"
     
    @msg1_h = "#{ambassador.first_name} #{ambassador.last_name} has joined the  #{ambassador.employer.company_name} team." 
    @msg1_t = @msg1_h 
    
    @msg2_h = "Track progress on your <a href='#{employer_url(ambassador.employer, :locale => nil, :anchor=>"ambassadors" )}'>#{Constants::SHORT_SITENAME} home page</a>.<br><br>" << 
            "Reach out to qualified software engineers by adding the \"Come Work With Us\" tab  to the #{ambassador.employer.company_name} corporate site, " << 
            "and by referring more team members to the social sharing tools."
    @msg2_t = Utils.html_to_txt(@msg2_h)

    @msg3_h = "If you have questions, just reply to this message to contact us at #{Constants::SHORT_SITENAME}."  
    @msg3_t = Utils.html_to_txt(@msg3_h)
    
    @msg_footer_h = employer_unsubscribe_link(true, ambassador.employer)
    @msg_footer_t = employer_unsubscribe_link(false, ambassador.employer)
    
    html_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_fyi_message', :formats => [:text], :handlers => [:erb], :layout => false
 
    return create_message ambassador.employer.email, subject, html_body, text_body       
  end

  private

  def create_simple_text_email(subject, salutation, content, signature, to_email, sender)
    @msg_salutation = salutation
    @msg_content = content
    @msg_signature = signature
   
    html_body = render_to_string 'fyi_mailer/create_personal_message', :formats => [:html], :handlers => [:erb], :layout => false
    text_body = render_to_string 'fyi_mailer/create_personal_message', :formats => [:text], :handlers => [:erb], :layout => false
    # See also Utils.html_to_txt for another way of converting HTML to txt, here and above.
    text_body = text_body.gsub("&nbsp;", " ")
    text_body = text_body.gsub("<br>", "\n")
    text_body = text_body.gsub("<hr>", "________________________________________")
    text_body = text_body.gsub(/<a\s+href\s*=\s*["'](.+?)["']>(.+?)<\/a>/, "\\2 ( \\1 )")

    return create_message(to_email, subject, html_body, text_body, sender)
  end
end

