class ApplicationController < ActionController::Base
  protect_from_forgery
  include UrlHelper
  include SessionsHelper
  before_filter :set_default_locale
  before_filter :check_uri
  before_filter :check_secret_param
 
   def check_uri
    #Note: To get SSL redirect,  Could do this in a 'before; filter. redirect_to :protocol => "https://" unless request.ssl?
    # Should use force_ssl=true and remove the redirect below, but that is only possible after we support https in the root rightjoin.io
     new_protocol =  switch_to_https(request)
    if Rails.env.staging?
      if new_protocol!=request.protocol.downcase
          redirect_to :protocol =>  new_protocol, :status => 301
      end
    end
    
		if Rails.env.production?
		  new_protocol = switch_to_https(request)
      host = request.host.downcase
      from = params["from"].to_s		  
		  
      if from.include?(Constants::SITENAME_IL_LC)
        # overrides the locale which was set earlier in set_default_locale
        set_default_locale(Constants::COUNTRY_IL) 
      end
      
      if from.include?(Constants::FIVEYEARITCH_SITENAME.downcase) 
        flash_message(:notice, "#{Constants::FIVEYEARITCH_SHORT_SITENAME} is now #{Constants::SITENAME}. Please go ahead and sign in." )
      end  
 
      if request.subdomain.blank?  || request.subdomain != "www"  || host.include?(Constants::FIVEYEARITCH_SITENAME.downcase) || host.include?(Constants::SITENAME_IL_LC) || new_protocol!=request.protocol.downcase
        port_str = (request.port==80 ? "" : ":"+request.port.to_s)
        redir_host  ="www." + Constants::SITENAME_LC
        orig_path= request.fullpath
        param_char = orig_path.include?("?") ? "&" : "?"
        redir_path = "#{orig_path}#{param_char}from=#{host}"
        url_with_www = new_protocol + redir_host + port_str +redir_path 
        
        redirect_to url_with_www, :status => 301
      end
    end
  end
  
  def check_secret_param
    if Rails.env.staging?
      if params[Constants::STAGING_SECRET_PARAM_NAME] != Constants::STAGING_SECRET_PARAM_VALUE
        unless request.path.start_with?('/auth/')
          redirect_to "/403.html", status: :gone
        end
      end
    end
  end

  def default_url_options(options={})
      ret = { :locale => I18n.t(:country_code, :locale => I18n.locale) }
      ret[:protocol] = "https://"  unless Rails.env.development?
      return ret
  end
  
  # Priority order for setting def.locale
  # 1. country from param
  # 2. country from host, e.g. rightjoin.co.il 
  # 3. set_locale_by_ip  , so long as it is a supported country. 
  #s
  # Note that country params here  is like  uk, il, ca, au, us
  def set_default_locale(country_code_from_domain = nil )
    
    country_code_param = params[:locale]#param like uk, ca, au, us
    
    if country_code_param.blank?
      country_code_param = country_code_from_domain
    end
    
    unless country_code_param.blank?
      locale_s = Constants::COUNTRIES[country_code_param]
    end 
    
    if locale_s.blank?
      I18n.locale = LocationUtils::locale_by_ip(request.remote_ip)
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
  
  def is_localhost?
    host = request.host.downcase
    host.start_with?("localhost") || host.start_with?("127.0.0.1") || host.start_with?("lvh.me")
  end
  
  def add_mandatory_fields_flash 
    if signed_in? && (current_user.first_name.blank? || current_user.last_name.blank?)      
      link = "#{view_context.link_to("fill in mandatory fields", register_path)}"
      html_for_flash = "Please #{link} in your profile to enable outbound contacts."
      
      flash_now_message(:notice, html_for_flash)
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

    pos_obj= pos.blank? ? nil : PositionTag.find_by_name_case_insensitive(pos)
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
      @voiceover << " Searching for other positions in <div class='release-constraint-box'  id='release-location-constraint'><span>#{ERB::Util.html_escape(loc)}</span><a title='Remove' class='with-tooltip'></a></div>" unless loc.blank?
      @voiceover << " Listing the most recent job postings" if loc.blank?
      @search_position = nil
    elsif fallback_loc
      @voiceover = "No results for <em>\"#{ERB::Util.html_escape(loc)}\"</em>."
      @voiceover << "  Searching for <div class='release-constraint-box'  id='release-position-constraint'><span>#{ERB::Util.html_escape(pos)}</span><a title='Remove' class='with-tooltip'></a></div> in other areas" unless pos.blank?
      @voiceover << "  Listing  the most recent job postings" if pos.blank?
      @search_location = nil
    else 
      if !pos.blank? && !loc.blank?
        @voiceover = "Searching for <div class='release-constraint-box'  id='release-position-constraint'><span>#{ERB::Util.html_escape(pos)}</span><a title='Remove' class='with-tooltip'></a></div> in <div class='release-constraint-box'  id='release-location-constraint'><span>#{ERB::Util.html_escape(loc)}</span><a title='Remove' class='with-tooltip'></a></div>"
      elsif !loc.blank?
        @voiceover = "Searching for jobs in <div class='release-constraint-box'  id='release-location-constraint'><span>#{ERB::Util.html_escape(loc)}</span><a title='Remove' class='with-tooltip'></a></div>"
      elsif !pos.blank?
        @voiceover = "Searching for <div class='release-constraint-box'  id='release-position-constraint'><span>#{ERB::Util.html_escape(pos)}</span><a title='Remove' class='with-tooltip'></a></div>"
      end
    end
    
    @voiceover << " in the category: <div class='release-constraint-box' id='release-board-constraint'><span>#{board_obj.title_case}</span><a title='Remove' class='with-tooltip'></a></div>" unless board_obj.blank?
  
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
    
    pos_obj= pos.blank? ? nil : PositionTag.find_by_name_case_insensitive(pos)
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
      @voiceover << " Searching for other titles in <div class='release-constraint-box'  id='release-location-constraint'><span>#{ERB::Util.html_escape(loc)}</span><a title='Remove' class='with-tooltip'></a></div>" unless loc.blank?
      @voiceover << " Listing most recent candidates" if loc.blank?
      @search_position = nil
    elsif fallback_loc
      @voiceover = "No results for <em>\"#{ERB::Util.html_escape(loc)}\"</em>."
      @voiceover << "  Searching for <div class='release-constraint-box'  id='release-position-constraint'><span>#{ERB::Util.html_escape(pos)}</span><a title='Remove' class='with-tooltip'></a></div> in other areas" unless pos.blank?
      @voiceover << "  Listing most recent candidates" if pos.blank?
      @search_location = nil
    else 
      if !pos.blank? && !loc.blank?
        @voiceover = "Searching for <div class='release-constraint-box'  id='release-position-constraint'><span>#{ERB::Util.html_escape(pos)}</span><a title='Remove' class='with-tooltip'></a></div> in <div class='release-constraint-box'  id='release-location-constraint'><span>#{ERB::Util.html_escape(loc)}</span><a title='Remove' class='with-tooltip'></a></div>"
      elsif !loc.blank?
        @voiceover = "Searching for candidates in <div class='release-constraint-box'  id='release-location-constraint'><span>#{ERB::Util.html_escape(loc)}</span><a title='Remove' class='with-tooltip'></a></div>"
      elsif !pos.blank?
        @voiceover = "Searching for <div class='release-constraint-box'  id='release-position-constraint'><span>#{ERB::Util.html_escape(pos)}</span><a title='Remove' class='with-tooltip'></a></div>"
      end
    end
    
    @voiceover << ", filtered by <div class='release-constraint-box'  id='release-skill-constraint'><span>#{@skill}</span><a title='Remove' class='with-tooltip'></a></div>" unless @skill.blank?
  end
  
private 
  def set_cookie_from_url_param(param)
    val = params[param]
    cookies[param] = {
       :value => val,
       :expires => 24.hour.from_now
    } unless val.blank?
  end
  
  def switch_to_https(request)
    return request.protocol.downcase == "http://" ? "https://" : request.protocol
  end
end
