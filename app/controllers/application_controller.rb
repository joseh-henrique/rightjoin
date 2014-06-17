class ApplicationController < ActionController::Base
  protect_from_forgery
  include UrlHelper
  include SessionsHelper
  before_filter :set_default_locale
  before_filter :check_uri

  def check_uri
    host = request.host
    if !host.include(".herokuapp.com") && 
       !host.start_with?("localhost") && 
       !host.start_with?("127.0.0.1") && 
       !host.start_with?("lvh.me") &&        
       !host.start_with?("10.0.0") && 
       !(Rails.env.development? && ( host.start_with?("192.168.0.") || host.start_with?("9.148."))) # Virtualbox; need to change this ip each time
      if request.subdomain.blank?
        port_str = (request.port==80 ?"": ":"+request.port.to_s) 
        url_with_www = request.protocol + "www." + Constants::SITENAME_LC+ port_str + request.fullpath
        
        headers["Status"] = "301 Moved Permanently"
        redirect_to url_with_www
      elsif request.subdomain != "www"
        redirect_to(jobs_url(:subdomain => "www", :board => request.subdomain))  
      end
    end
  end

  def default_url_options(options={})
    { :locale => I18n.t(:country_code, :locale => I18n.locale) }
  end
  
  # default is US, if it's Canada go with it, use set_locale_by_ip for full geotargeting
  def set_default_locale
    country_code_param = params[:locale]#param like uk, ca, au, us
    locale_s = Constants::COUNTRIES[country_code_param] unless country_code_param.blank?
    if locale_s.blank?
      I18n.locale = LocationUtils::locale_by_ip(request.remote_ip)
      if I18n.locale != Constants::COUNTRIES[Constants::COUNTRY_CA]
        I18n.locale =  Constants::LOCALE_EN.to_sym
      end
    else
      I18n.locale = locale_s.to_sym 
    end
  end
  
  # use for geotargeting
  def set_locale_by_ip
    country_code_param = params[:locale]#param like uk, ca, au, us
    locale_s = Constants::COUNTRIES[country_code_param] unless country_code_param.blank?
    if locale_s.blank?
      I18n.locale = LocationUtils::locale_by_ip(request.remote_ip)
    else
      I18n.locale = locale_s.to_sym 
    end
  end  
  
  def add_verif_flash 
    if signed_in? and current_user.pending?
      verification_path = current_user.employee? ? verify_user_path(current_user, :locale => current_user.country_code) : verify_employer_path(current_user)
      verification_form = 
         "<form id='verify-account-form' action='#{verification_path}' method='post' data-remote='true' style='display:inline'>" +             
                "   <input type='password' id='verification-pw' name='user[password]'>" +                 
                "   <input type='hidden'  name='user[email]' value ='#{current_user.email}'>" +
                "   <input type='submit' id='verify-account-btn' value='Activate' />" +
                " </form>"
      
      html_for_flash = "To #{current_user.class.short_reason_to_verify}, please enter the password 
                            <a title='If you haven&apos;t received it in a minute or so, please check your 
                            spam folder, or sign out and click \u201CForgot Password.\u201D'>we sent you</a>: 
                              <span class=\"verification-box\">#{verification_form}</span>"
      
      flash_now_message(:activate, html_for_flash)
    end
  end
  
  def log_model_errors(model_obj)
    has_errors = false
    return unless model_obj
    model_obj.errors.full_messages.each do |err| 
      logger.error err
      has_errors = true
    end
    has_errors
  end
  
  def flash_clear
    view_context.flash_clear
  end
  
  def flash_message(type, text)
   # 'unless' clause is needed because before_filter may be called multiple times per request
      unless flash and flash[type] and flash[type].include? text
        logger.info "Flash: #{text}"
        flash[type] ||= []
        flash[type] << text
      end 
  end
  
  def flash_now_message(type, text)
       # 'unless' clause is needed because before_filter may be called multiple times per request
       unless flash.now and flash.now[type] and flash.now[type].include? text
        logger.info "Flash now: #{text}"
        flash.now[type] ||= []
        flash.now[type] << text
      end
  end
  
  def strip_params
      strip_in_values(params)#must do it recursively because Rails forms nest params by model class, e.g., params[:user][:email]
  end  
  
  def strip_in_values(hsh)
      hsh.each do |key, value| 
        hsh[key] = value.strip if value.respond_to?('strip')
        strip_in_values(value) if value.respond_to?('each')
      end
  end
  
  def raise_routing_error(params = nil)
    raise ActionController::RoutingError.new(params || 'Not Found')
  end
  
  def search_jobs 
    pos = params[:wantedposition]    
    loc = params[:location]
    latitude = params[:lat]
    longitude = params[:lng]

    pos_obj= pos.blank? ? nil : PositionTag.find_by_name(pos)
    loc_obj = loc.blank? ? nil : LocationTag.find_by_name(loc)
    loc_obj ||= LocationTag.new(:name => loc, :latitude => latitude.to_f, :longitude => longitude.to_f) if !loc.blank? && !latitude.blank? && !longitude.blank?
    
    # still empty, try quire geonames
    if loc_obj.nil? && !loc.blank?
      lookup_loc = LocationUtils.search(loc, I18n.t(:country_code, :locale => I18n.locale))
      loc_obj = LocationTag.new(:name => loc, :latitude => lookup_loc[:latitude], :longitude => lookup_loc[:longitude]) if lookup_loc
    end
    
    board_obj = Board.find_by_name(params[:board])

    @board = board_obj
    @search_position = pos_obj
    @search_location = loc_obj
    @voiceover = "Listing the most recent job postings"
    
    fallback_pos = fallback_loc = false
    
    fallback_pos = !pos.blank? && pos_obj.nil?
    fallback_loc = !loc.blank? &&  loc_obj.nil?

    loc_cond = []
    unless loc_obj.nil?
      if loc_obj.relocation?
        loc_cond << ["allow_relocation = ?", true]
      elsif loc_obj.telecommute?
        loc_cond << ["allow_telecommuting = ?", true]
      elsif loc_obj.coordinates?
        loc_cond << ["? <= northmost", loc_obj.latitude]
        loc_cond << ["? >= westmost", loc_obj.longitude]
        loc_cond << ["? >= southmost", loc_obj.latitude]
        loc_cond << ["? <= eastmost", loc_obj.longitude]
      elsif not loc_obj.new_record?
        loc_cond << ["location_id = ?", loc_obj.id]
      end
    end 
    
    pos_cond = nil
    unless pos_obj.nil?
      if pos_obj.family_id.nil?
        pos_cond = ["position_id = ?", pos_obj.id]
      else
        pos_cond = ["position_id in (select position_tags.id from position_tags where position_tags.family_id = ?)", pos_obj.family_id]
      end
    end
    
    board_cond = board_obj.blank? ? "exists (select * from ads where ads.job_id = jobs.id)" : ["exists (select * from ads where ads.job_id = jobs.id and ads.board_id = ?)", board_obj.id]
    locale_cond = ["locale = ?", I18n.locale.to_s]
    
    conditions = []
    conditions.concat loc_cond
    conditions << board_cond unless board_cond.nil?
    conditions << pos_cond unless pos_cond.nil?
    conditions << locale_cond
    
    select = []
    select << ["position_id = ? as primary_pos", pos_obj.id] if !pos_obj.nil? && !pos_obj.family_id.nil?
    
    orderby = []
    orderby << "primary_pos DESC" if !pos_obj.nil? && !pos_obj.family_id.nil?
    orderby << "display_order DESC"

    u = Job.default_paginate(params, select, conditions, orderby)
    if u.empty? && !loc_cond.empty?
      conditions.clear
      conditions << locale_cond
      conditions << pos_cond unless pos_cond.nil?
      conditions << board_cond unless board_cond.nil?
      fallback_loc = true
      #re-search NOT using loc, only pos and skills
      u = Job.default_paginate(params, select, conditions, orderby)
    end
    
    if u.empty? && !pos_cond.nil?
      conditions.clear
      conditions << locale_cond
      conditions << board_cond unless board_cond.nil?
      fallback_pos = true
      #re-search NOT using loc and pos, only board
      u = Job.default_paginate(params, select, conditions, orderby)
    end
    
    @jobs = u
    
    if fallback_pos && fallback_loc
      @voiceover = "No results for <em>\"#{ERB::Util.html_escape(pos)}\"</em> and <em>\"#{ERB::Util.html_escape(loc)}\"</em>. Listing the most recent job postings."
      @search_position = nil
      @search_location = nil
    elsif fallback_pos
      @voiceover = "No results for <em>\"#{ERB::Util.html_escape(pos)}\"</em>."
      @voiceover << " Searching for other positions in <div class='release-constraint-box'  id='release-location-constraint'><span>#{ERB::Util.html_escape(loc)}</span><a title='Remove'></a></div>" unless loc.blank?
      @voiceover << " Listing the most recent job postings" if loc.blank?
      @search_position = nil
    elsif fallback_loc
      @voiceover = "No results for <em>\"#{ERB::Util.html_escape(loc)}\"</em>."
      @voiceover << "  Searching for <div class='release-constraint-box'  id='release-position-constraint'><span>#{ERB::Util.html_escape(pos)}</span><a title='Remove'></a></div> in other areas" unless pos.blank?
      @voiceover << "  Listing  the most recent job postings" if pos.blank?
      @search_location = nil
    else 
      if !pos.blank? && !loc.blank?
        @voiceover = "Searching for <div class='release-constraint-box'  id='release-position-constraint'><span>#{ERB::Util.html_escape(pos)}</span><a title='Remove'></a></div> in <div class='release-constraint-box'  id='release-location-constraint'><span>#{ERB::Util.html_escape(loc)}</span><a title='Remove'></a></div>"
      elsif !loc.blank?
        @voiceover = "Searching for jobs in <div class='release-constraint-box'  id='release-location-constraint'><span>#{ERB::Util.html_escape(loc)}</span><a title='Remove'></a></div>"
      elsif !pos.blank?
        @voiceover = "Searching for <div class='release-constraint-box'  id='release-position-constraint'><span>#{ERB::Util.html_escape(pos)}</span><a title='Remove'></a></div>"
      end
    end
    
    @voiceover << " in the category: <div class='release-constraint-box' id='release-board-constraint'><span>#{board_obj.title_case}</span><a title='Remove'></a></div>" unless board_obj.blank?
  
    if ((fallback_pos || fallback_loc) && !signed_in?)
        register_txt = "#{view_context.link_to("Register", register_path)} and let employers invite you to escape-worthy jobs that meet your requirements." 
        @voiceover << "<div class='more-text'>#{register_txt}</div>"
    end
    
    # build a map of existing infointerviews of this user to the returned jobs
    @infointerviews = {}
    employee = get_employee_user_by_session_cookie
    unless employee.nil?
      employee.infointerviews.where(:job_id => @jobs.map(&:id)).all.each{|ii| @infointerviews[ii.job_id] = ii}
    end
  end
  
  def search_users    
    pos = params[:wantedposition]    
    loc = params[:location]
    latitude = params[:lat]
    longitude = params[:lng]
    job_id = params[:for]
    job_id ||= params[:jobid]
    
    begin
      job_obj = job_id.blank? ? nil : Job.find(job_id)
      if !job_obj.nil? && job_obj.employer != current_user
        job_obj = nil
      end
    rescue # ignore the exception
    end
    
    if job_obj && params[:for].present?
      pos = job_obj.position_name
      loc = job_obj.location_name
    end  
    
    pos_obj= pos.blank? ? nil : PositionTag.find_by_name(pos)
    loc_obj = loc.blank? ? nil : LocationTag.find_by_name(loc)
    loc_obj ||= LocationTag.new(:name => loc, :latitude => latitude.to_f, :longitude => longitude.to_f) if !loc.blank? && !latitude.blank? && !longitude.blank?
    
    # still empty, try quire geonames
    if loc_obj.nil? && !loc.blank?
      lookup_loc = LocationUtils.search(loc, I18n.t(:country_code, :locale => I18n.locale))
      loc_obj = LocationTag.new(:name => loc, :latitude => lookup_loc[:latitude], :longitude => lookup_loc[:longitude]) if lookup_loc
    end

    @search_position = pos_obj
    @search_location = loc_obj
    @job = job_obj
    @skill = params["skill"]
    @voiceover = "Listing most recent candidates"
    
    if pos_obj.nil?
      popular_skills = SkillTag.popular_for_role()
    else
      unless pos_obj.family_position.nil?
        popular_skills = SkillTag.popular_for_position_family(pos_obj.family_position.id)
      else
        popular_skills = SkillTag.popular_for_role(pos_obj.name)
      end
    end
    
    @popular_skills = popular_skills.select {|element| element if element.name != @skill}
    
    fallback_pos = fallback_loc = false
    
    fallback_pos = !pos.blank? && pos_obj.nil?
    fallback_loc = !loc.blank? &&  loc_obj.nil?

    loc_cond = []
    unless loc_obj.nil?
      if loc_obj.relocation?
        loc_cond << ["can_relocate = ?", true]
      elsif loc_obj.telecommute?
        loc_cond << ["can_telecommute = ?", true]
      elsif loc_obj.coordinates?
        loc_cond << ["? <= northmost", loc_obj.latitude]
        loc_cond << ["? >= westmost", loc_obj.longitude]
        loc_cond << ["? >= southmost", loc_obj.latitude]
        loc_cond << ["? <= eastmost", loc_obj.longitude]
      elsif not loc_obj.new_record?
        loc_cond << ["location_id = ?", loc_obj.id]
      end
    end 
    
    pos_cond = nil
    unless pos_obj.nil?
      if pos_obj.family_id.nil?
        pos_cond = ["wanted_position_id = ?", pos_obj.id]
      else
        pos_cond = ["wanted_position_id in (select position_tags.id from position_tags where position_tags.family_id = ?)", pos_obj.family_id]
      end
    end
    
    locale_cond = ["locale = ?", I18n.locale.to_s]
    skill_cond = @skill.blank? ? nil : ["exists (select * from user_skills inner join skill_tags on user_skills.skill_tag_id = skill_tags.id where users.id = user_skills.user_id and skill_tags.name = ?)", @skill.to_s]
    
    conditions = []
    conditions.concat loc_cond
    conditions << skill_cond unless skill_cond.nil?
    conditions << pos_cond unless pos_cond.nil?
    conditions << locale_cond
    
    select = []
    select << ["wanted_position_id = ? as primary_pos", pos_obj.id] if !pos_obj.nil? && !pos_obj.family_id.nil?
    
    orderby = []
    orderby << "primary_pos DESC" if !pos_obj.nil? && !pos_obj.family_id.nil?

    u = User.default_paginate(params, select, conditions, orderby)
    if u.empty? && !loc_cond.empty?
      conditions.clear
      conditions << locale_cond
      conditions << pos_cond unless pos_cond.nil?
      conditions << skill_cond unless skill_cond.nil?
      fallback_loc = true
      #re-search NOT using loc, only pos and skills
      u = User.default_paginate(params, select, conditions, orderby)
    end
    
    if u.empty? && !pos_cond.nil?
      conditions.clear
      conditions << locale_cond
      conditions << skill_cond unless skill_cond.nil?
      fallback_pos = true
      #re-search NOT using loc and pos, only skills
      u = User.default_paginate(params, select, conditions, orderby)
    end
    
    @users = u
    
    if fallback_pos && fallback_loc
      @voiceover = "No results for <em>\"#{ERB::Util.html_escape(pos)}\"</em> and <em>\"#{ERB::Util.html_escape(loc)}\"</em>. Listing most recent candidates"
      @search_position = nil
      @search_location = nil
    elsif fallback_pos
      @voiceover = "No results for <em>\"#{ERB::Util.html_escape(pos)}\"</em>."
      @voiceover << " Searching for other titles in <div class='release-constraint-box'  id='release-location-constraint'><span>#{ERB::Util.html_escape(loc)}</span><a title='Remove'></a></div>" unless loc.blank?
      @voiceover << " Listing most recent candidates" if loc.blank?
      @search_position = nil
    elsif fallback_loc
      @voiceover = "No results for <em>\"#{ERB::Util.html_escape(loc)}\"</em>."
      @voiceover << "  Searching for <div class='release-constraint-box'  id='release-position-constraint'><span>#{ERB::Util.html_escape(pos)}</span><a title='Remove'></a></div> in other areas" unless pos.blank?
      @voiceover << "  Listing most recent candidates" if pos.blank?
      @search_location = nil
    else 
      if !pos.blank? && !loc.blank?
        @voiceover = "Searching for <div class='release-constraint-box'  id='release-position-constraint'><span>#{ERB::Util.html_escape(pos)}</span><a title='Remove'></a></div> in <div class='release-constraint-box'  id='release-location-constraint'><span>#{ERB::Util.html_escape(loc)}</span><a title='Remove'></a></div>"
      elsif !loc.blank?
        @voiceover = "Searching for candidates in <div class='release-constraint-box'  id='release-location-constraint'><span>#{ERB::Util.html_escape(loc)}</span><a title='Remove'></a></div>"
      elsif !pos.blank?
        @voiceover = "Searching for <div class='release-constraint-box'  id='release-position-constraint'><span>#{ERB::Util.html_escape(pos)}</span><a title='Remove'></a></div>"
      end
    end
    
    @voiceover << ", filtered by <div class='release-constraint-box'  id='release-skill-constraint'><span>#{@skill}</span><a title='Remove'></a></div>" unless @skill.blank?
  end
  
private 
  def set_cookie_from_url_param(param)
    val = params[param]
    cookies[param] = {
       :value => val,
       :expires => 24.hour.from_now
    } unless val.blank?
  end
end
