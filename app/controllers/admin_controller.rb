class AdminController < ApplicationController

  before_filter :init_employee_user, :check_admin
  def check_admin
    redirect_to root_path unless current_user && current_user.admin
  end

  ITEMS_PER_REPORT=5

  def console
    render 'admin/console', :layout => "admin"
  end

  def inactivate_candidate
    id = params[:id]
    user = User.find(id)

    user.deactivate
    flash_message(:notice, "User was inactivated")

  rescue Exception => e
    flash_message(:error, e.message)
  ensure
    redirect_to admin_events_path(:days_ago => params[:days_ago])
    end

  def locations
    @locale = params[:locale]
    locations = User.find_all_by_northmost(nil).find_all{|o| o.location != nil && o.status==UserConstants::VERIFIED && o.locale == @locale}.map{|o| [o.location.name, o.location.id]}
    locations.concat Job.find_all_by_northmost(nil).find_all{|o| o.location != nil && o.status == Job::PUBLISHED && o.locale == @locale}.map{|o| [o.location.name, o.location.id]}

    @locations = locations.uniq {|l|l[0]}

    render 'admin/locations', :layout => "admin"
  end

  def manage_location
    locale = params[:locale]
    action = params[:what]

    invalid_location_id = params[:invalid_location]
    invalid_location = LocationTag.find(invalid_location_id)

    lat = params[:lat].to_f
    lng = params[:lng].to_f

    raise "invalid or missing coordinates" if lat == 0 || lng == 0

    if action == "set_coordinates"
      invalid_location.fix_coordinates_for_associated_users_and_jobs(lat, lng)
      flash_message(:notice, "Coordinates were set")
    elsif action == "swap"
      correct_location = LocationTag.find_or_create_by_params(params)
      raise "Failed to retrieve or create new location" if correct_location.nil?

      invalid_location.replace_locations_for_associated_objects(correct_location)
      # should not be in use, can be safely deleted
      invalid_location.destroy
      flash_message(:notice, "The location was replaced")
    end
  rescue Exception => e
    flash_message(:error, e.message)
  ensure
    redirect_to admin_locations_path(:locale => locale)
  end

  def positions
    positions = PositionTag.joins("RIGHT JOIN users ON users.wanted_position_id = position_tags.id").where("position_tags.family_id is null").select("position_tags.name, position_tags.id").map {|pos| [pos.name, pos.id]}
    positions.concat PositionTag.joins("RIGHT JOIN jobs ON jobs.position_id = position_tags.id").where("position_tags.family_id is null").select("position_tags.name, position_tags.id").map {|pos| [pos.name, pos.id]}
    
    sorted_by_frequencey_positions = positions.each_with_object(Hash.new(0)) { |pos, hash| hash[pos] += 1 }.sort_by {|k, v| v}
    @positions = sorted_by_frequencey_positions.map {|pos| pos[0]}.reverse

    render 'admin/positions', :layout => "admin"
  end

  def attach_position
    invalid_pos_id = params[:invalid_position]
    fixed_pos_name = params[:fixed_position]
    family_pos_name = params[:family_position]
    add_to_autocomplete = params[:autocomplete] == "1" # also freezes capitlization

    raise "invalid parameters" if invalid_pos_id.blank? || fixed_pos_name.blank?
    
    invalid_pos = PositionTag.find_by_id(invalid_pos_id)
    raise "Position #{invalid_pos_id} doesn't exist" if invalid_pos.blank?

    new_attrs = Hash.new
    family_set = false

    unless family_pos_name.blank?
      if fixed_pos_name.downcase == family_pos_name.downcase
        new_attrs[:family_id] = invalid_pos.id
        family_set = true
      else
        family_pos = PositionTag.find_by_name_case_insensitive(family_pos_name)
        raise "Position #{family_pos_name} doesn't exist" if family_pos.blank?
        
        if family_pos.family_id.nil?
          family_pos.update_attributes(family_id: family_pos.id)
        end
        
        new_attrs[:family_id] = family_pos.family_id
        family_set = true
      end
    end
    
    if add_to_autocomplete
      if family_set
        new_attrs[:priority] = 1
      else
        flash_message(:error, "Position must be assigned to a family to be used for autocomplete")
      end
    end
    
    new_attrs[:name] = fixed_pos_name
    
    invalid_pos.update_attributes(new_attrs)
    flash_message(:notice, "The positions has been updated")
  rescue Exception => e
    flash_message(:error, e.message)
  ensure
    redirect_to admin_positions_path
  end

  def skills
    @skills = SkillTag.joins(:user_skills).select("skill_tags.id, skill_tags.name, COUNT(*) AS total").group("skill_tags.id").having("skill_tags.priority = 0  and COUNT(*) > 1").order("total desc")

    render 'admin/skills', :layout => "admin"
  end

  def approve_skill
    counter = 0
    skill_ids = params[:skill]
    skill_ids.each_key do |id|
      tag = SkillTag.find(id)
      tag.update_attribute(:priority, 1)
      counter += 1
    end
    flash_message(:notice, "#{counter} skills have been updated")
  rescue Exception => e
    flash_message(:error, e.message)
  ensure
    redirect_to admin_skills_path
  end

  def approve_invite
    approve = params[:approve]
    id = params[:id]
    invite = Interview.find(id)
    if approve == "true"
      invite.approve!
      flash_message(:notice, "The invite was approved")
    elsif approve == "false"
      invite.reject!
      flash_message(:notice, "The invite was rejected")
    end
  rescue Exception => e
    flash_message(:error, e.message)
  ensure
    redirect_to admin_invites_to_approve_path
  end

  def close_job
    job_id = params[:id]
    job = Job.find(job_id)
    job.shutdown!(Interview::CLOSED_NOT_APPROVED)
    flash_message(:notice, "The job was closed")
  rescue Exception => e
    flash_now_message(:error, e.message)
  ensure
    redirect_to admin_events_path(:days_ago => params[:days_ago])
    end

  def recommend_candidates
    job_id = params[:id]
    @job = Job.find(job_id)

    @location = params[:location]
    @skill = params[:skill]

    @candidates = @job.list_candidates(@location, @skill, 100)
  rescue Exception => e
    flash_now_message(:error, e.message)
  ensure
    render 'admin/recommend_candidates', :layout => "admin"
  end

  def recommend_candidate_to_job
    job = Job.find(params[:job_id])
    candidate = User.find(params[:id])

    raise "Invalid parameters" if job.nil? || candidate.nil?

    job.recommend(candidate)
    flash_message(:notice, "The candidate was successfully recommended")

  rescue Exception => e
    
    flash_message(:error, e.message)
  ensure
    redirect_to admin_recommend_candidates_path(:id => params[:job_id], :skill => params[:skill], :location => params[:location])
    end

  def send_jobs_update_to_engineers
    counter = 0
    Reminder.send_jobs_update_to_engineers do |invites|
      new_msg = FyiMailer.create_engineer_update_email(invites.first.user, invites)
      Utils.deliver new_msg
      counter += 1
    end
    flash_message(:notice, "#{counter} updates were sent to engineers")
  rescue Exception => e
    logger.error(e)
    flash_message(:error, e.message)
  ensure
    redirect_to admin_path
  end

  def send_jobs_update_to_employers
    counter = 0
  	Reminder.send_jobs_update_to_employers do |empr, all_jobs, open_jobs, just_expired_jobs|
       new_msg = FyiMailer.create_employer_update_email(empr, all_jobs, open_jobs, just_expired_jobs)
       Utils.deliver new_msg
       counter += 1
     end
    flash_message(:notice, "#{counter} updates were sent to employers")
  rescue Exception => e
    puts e.backtrace
     logger.error(e)
    flash_message(:error, e.message)
  ensure
    redirect_to admin_path
  end

  def send_welcome_email_to_employers
    counter = 0
    Reminder.send_personal_welcome_message(Employer) do |employer|
      new_msg = FyiMailer.create_personal_welcome_employer_email(employer)
      Utils.deliver new_msg
      counter += 1
    end

    flash_message(:notice, "#{counter} welcome emails were sent to employers")
  rescue Exception => e
    logger.error(e)
    flash_message(:error, e.message)
  ensure
    redirect_to admin_path
  end

  def send_welcome_email_to_engineers
    counter = 0
    Reminder.send_personal_welcome_message(User) do |user|
      new_msg = FyiMailer.create_personal_welcome_candidate_email(user)
      Utils.deliver new_msg
      counter += 1
    end

    flash_message(:notice, "#{counter} welcome emails were sent to engineers")
  rescue Exception => e
    flash_message(:error, e.message)
  ensure
    redirect_to admin_path
  end

  def send_update_employers_about_new_contacts
    counter = 0
    Reminder.update_employers_about_new_contacts do |employer|
      new_msg = FyiMailer.update_employers_about_new_contacts(employer)
      Utils.deliver new_msg
      counter += 1
    end
    flash_message(:notice, "#{counter} new-ambassador-contact emails were sent to employers")
  rescue Exception => e
    logger.error(e)
    flash_message(:error, e.message)
  ensure
    redirect_to admin_path
  end
  
  def send_update_employers_about_new_comments
    counter = 0
    Reminder.update_employers_about_new_comments do |comment|
      new_msg = FyiMailer.update_employer_about_new_comment(comment)
      Utils.deliver new_msg
      counter += 1
    end
    flash_message(:notice, "#{counter} new-comments emails were sent to employers")
  rescue Exception => e
    logger.error(e)
    flash_message(:error, e.message)
  ensure
    redirect_to admin_path
  end  

  def send_update_to_admin
    Reminder.send_admin_summary do |events|
      new_msg = FyiMailer.create_admin_summary_email("Debug: admin console", events)
      Utils.deliver new_msg
    end

    flash_message(:notice, "Update email was successfully sent to admin")
  rescue Exception => e
    flash_message(:error, e.message)
  ensure
    redirect_to admin_path
  end

  def events
    @days_ago = params[:days_ago]
    @days_ago ||= 0
    @days_ago = @days_ago.to_i
    events = Reminder.where(:created_at => Date.today - @days_ago.days..Date.today - @days_ago.days + 1.days)

    @new_candidates = events.select {|e| e.reminder_type == Reminder::USER_ACCOUNT_ACTIVATED.to_s}.map{|e| User.find(e.linked_object_id)}
    @new_employers = events.select {|e| e.reminder_type == Reminder::EMPLOYER_ACCOUNT_ACTIVATED.to_s}.map{|e| Employer.find(e.linked_object_id)}
    @created_jobs = events.select {|e| e.reminder_type == Reminder::JOB_CREATED.to_s}.map{|e| Job.find(e.linked_object_id)}
    @companies_rated = events.select {|e| e.reminder_type == Reminder::COMPANY_RATED_ACTION.to_s}.map{|e| CompanyRating.find(e.linked_object_id)}
  end

  def import_jobs
    begin
      res = Job.import_fyi_jobs(params[:csv_url])
      flash_message(:notice, "Imported #{res[:jobs].count} out of #{res[:total_rows_count]}")
    rescue Exception => e
      flash_message(:error, e.message)
    ensure
      redirect_to admin_path
    end
  end

  def invites_to_approve
    @invites_to_approve = Interview.where("status = #{Interview::AWAITING_APPROVAL}")
  end

  def report_statistics
    @percent_who_dont_want_to_switch_job_titles =  percent_who_dont_want_to_switch_job_titles
    @most_common_skill_tags =  most_common_skill_tags
    @most_common_expert_tags = most_common_skill_tags(nil, UserSkill::EXPERT)

    @skill_names= [ "java", "c#", 'c', 'c++']
    @most_common_learning_tags_for_experts_in={}

    @skill_names.each {|skill_name|
      @most_common_learning_tags_for_experts_in[skill_name]=most_common_learning_skill_tags_for_experts_in(skill_name)
    }

    @most_common_learning_tags = most_common_skill_tags(nil, UserSkill::LEARNER)
    @most_common_requirement_names = most_common_requirement_names

    render 'admin/inspect', :layout => "admin"
  end

  # Most common learning skill tags for  experts at the given skill.
  # Return Array of pairs like [["python", 9], ["ruby", 7], ["scala", 5]]
  def most_common_learning_skill_tags_for_experts_in(name)
    return most_common_skill_tags(users_at_skill_level(name, UserSkill::EXPERT),UserSkill::LEARNER)
  end

  def percent_who_dont_want_to_switch_job_titles
    results_array=ActiveRecord::Base.connection.execute("select count(*) from users where sample is NOT TRUE and status =1 and  wanted_position_id =current_position_id");
    count_hash= results_array[0]
    count_s= count_hash['count']
    count=count_s.to_f
    all = non_sample_active_users.length
    frac= (count/all).round(2)
    return (frac*100).round(0)
  end

  # Most common tags among these users at the given skill level.
  # If users parameter is nil, then choose all non-sample active users
  # Return Array of pairs like [["python", 9], ["ruby", 7], ["scala", 5]]
  # Equivalent SQL is
  # select  s.name,count(*) from users u, user_skills us, skill_tags s
  #                     where u.sample is NOT TRUE and u.status = 1 and us.user_id=u.id and us.skill_tag_id =s.id
  #                      group by s.id order by count(*) desc;
  def most_common_skill_tags(users=nil, level=nil)
    users = non_sample_active_users unless users
    skill_names_nested = users.map {|u| skill_names(u,level) }
    all_skill_names_at_this_level = skill_names_nested.flatten
    return Utils::top(all_skill_names_at_this_level, ITEMS_PER_REPORT)
  end

  # Most common requirements
  # Return Array of pairs like [["ace colleagues", 9], ["kegerator", 7]]
  def most_common_requirement_names()
    users = non_sample_active_users
    req_names_nested = users.map {|u| ujqs=u.user_job_qualifiers; ujqs.map{|ujq|ujq.job_qualifier_tag.name }}
    req_names = req_names_nested.flatten
    return  Utils::top(req_names, ITEMS_PER_REPORT)
  end

  private

  # Skills which the user has at this level
  def skill_names(user, level=nil)

    if level
    user_skills = user.user_skills.find_all_by_seniority(level)
    else
    user_skills = user.user_skills
    end

    ret = user_skills.map{|us|us.skill_tag.name}
    return ret
  end

  # All users who are neither sample nor  which the user has at this level
  # Cached per-request
  # Equivalent SQL is select  count(*) from users where sample is NOT TRUE and status =1
  def non_sample_active_users
    @non_sample_active_users = User.find_all_by_sample_and_status(nil,UserConstants::VERIFIED) unless @non_sample_active_users
    return @non_sample_active_users
  end

  # Users who are at the given level at the given skill
  # If level nil, then all levels.
  def users_at_skill_level(name, level)
    ret = non_sample_active_users.find_all{|u| xs_names = skill_names(u, level); xs_names.include?(name);}
    return ret
  end

end