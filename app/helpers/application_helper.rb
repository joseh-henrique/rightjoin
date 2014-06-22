module ApplicationHelper 
  # Return a title on a per-page basis.
  def title
    base_title = Constants::SHORT_SITENAME.clone
    extra_text = ""
    unless @current_page_info.nil?
      if @current_page_info[:intended_for] == :employee
        base_title = Constants::CANDIDATE_TAGLINE.clone
      elsif @current_page_info[:intended_for] == :employer
        base_title = Constants::EMPLOYER_TAGLINE.clone
      end
      
      extra_text = " | #{@current_page_info[:title]}"
    end
    
    if I18n.locale.to_s != Constants::LOCALE_EN
       base_title << " - #{I18n.t :short_country_name}"
    end
    
    "#{base_title}#{extra_text}"
  end
  
  
  def flash_clear
    flash.clear
  end

  def extra_keywords
    if @current_page_info.nil?
      ""
    else
      @current_page_info[:extra_keywords] or ""
    end
  end
  

  def css_class_for_current_page
    if @current_page_info.nil?
      ""
    else
      @current_page_info[:id]
    end
  end
  

    
  def shorten_blog_txt(full_desc, max_line_len)
    descr = strip_tags(full_desc)
    if descr.length > max_line_len
      descr = descr[0, max_line_len] << "&nbsp;&nbsp;...&nbsp;&nbsp;"
    end
    return raw descr
  end

  def full_image_url(img)
    "#{request.protocol}#{request.host_with_port}#{image_path(img)}"
  end

  
  def job_qualifier_s(for_view )
    if for_view==:employee
      return "What you need from your next job"
    elsif for_view==:searcher || for_view==:employer
       return "Requirements"
    else
      raise "for_view #{for_view}, unknown" unless Rails.env.production?
    end
  end
  
  #Refactoring opportunity Replace :for_view=>:employee/searcher with  @current_page_info[:intended_for] 
  # because
  # (1) that way, there is no need for any param passed in
  # (2) this makes it consistent with other places  where we use @current_page_info[:intended_for] 
  # (3) there are only 2 possible values, so true/false is enough, there is no need for a confusing, potentially multivalent, :for_view  
  def current_job_s(for_view)
    if for_view==:employee
      "Your current safe but not quite satisfying job"
    elsif for_view==:searcher || for_view==:employer
      "Current job title"
    else
      raise "for_view #{for_view} unknown" unless Rails.env.production?
    end
  end
  
  def wanted_job_s(for_view)
    if for_view==:employee
      "The job that will scratch your itch"
    elsif for_view==:searcher || for_view==:employer
      "Job title targeted by candidate"
    else
      raise "for_view #{for_view} unknown" unless Rails.env.production?
    end
  end
  
  def skills_s(for_view)
    if for_view==:employee
      "Your hot skills, with experience level in each"
    elsif for_view==:searcher || for_view==:employer
      "Skills, with experience level"
    else
      raise "for_view #{for_view} unknown" unless Rails.env.production?
    end
  end
  
  def wanted_salary_s(for_view)
    if for_view==:employee
      "The #{I18n.t(:salary_period)} salary that will get you out of bed"
    elsif for_view==:searcher || for_view==:employer
      "Candidate's #{I18n.t(:salary_period)}  salary requirement"
    else
      raise "for_view #{for_view} unknown" unless Rails.env.production?
    end
  end
  
  def free_text_s(for_view, for_edit=false)
    if for_view==:employee
       s = "Anything else you'd like to say to employers?"
       if for_edit
        s << " No need for details, that can come after you return their ping."
       end
       return s
    elsif for_view==:searcher || for_view==:employer
       "A short message from the candidate"
    else
      raise "for_view #{for_view} unknown" unless Rails.env.production?
    end
  end  
  
  def city_s(for_view)
    
    if for_view==:employee
      "Where you want to work"
    elsif for_view==:searcher || for_view==:employer
      "Metropolitan area"
    else
      raise "for_view #{for_view} unknown" unless Rails.env.production?
    end
    
  end
  
  # Used only for user, not employer 
  def show_page_s(status)
    raise  "Did not expect Employer" if Rails.env.development? && @user.class==Employer
    if status == UserConstants::PENDING  
      res = "Your profile is <em>pending verification</em>.
      Verify it by entering the password that we sent you.
      Or sign out and choose \u201CForgot Password\u201D for a new one."
      
    elsif status == UserConstants::VERIFIED  
      res = @user.class.capabilities_header # only user, not employer
    else #UserConstants::DEACTIVATED
      res = "Your #{Constants::SHORT_SITENAME} profile is <em>inactive and not visible</em> to anyone but you.
            You can  <a id='status-activate-top' uid='#{@user.id}'>re-activate</a>."
      
    end
    res.html_safe
  end
  
  def seniority_s(seniority)
     UserSkill.seniority_s(seniority)
  end
  
  def page_leaving_warning_s()
    return "Any unsaved content will be lost."
  end
     
  def verified_flash_s
    "Your account is now verified. For maximum security, we recommend you change your password, above."
  end  
  
  def  uservoice_contact_link(txt ="contact us")
      # First param is a fallback in case form does not work.
   extra_param_for_uv = %Q^id="uservoice-contact" data-uv-trigger^
		contact_link(txt, extra_param_for_uv)
  end
   
  def email_contact_link(txt ="contact us")
     contact_link(txt, "")
  end
     
  def contact_link(txt, extra_param_for_uv="")
      %Q^<a href="mailto:#{Constants::CONTACT_EMAIL}"#{extra_param_for_uv}>#{txt}</a>^.html_safe
  end
  private :contact_link
  
   # This method has some duplication with all_country_flag_links. They could be refactored to share code. 
  def country_links_as_sentence(options={})
      exclude = options[:exclude]
      path = options[:path] || method(:country_root_url)
      links=[]
      Constants::COUNTRIES.each_key do |country_code|#us,uk,ca,au
         locale_ = Constants::COUNTRIES[country_code]# locale_ like en-GB
         unless locale_ == exclude.to_s
            country_name = I18n.t(:country_name,:locale => locale_)
            links << link_to(country_name, path.call(:locale => country_code ))
         end
      end 
      return raw links.to_sentence
  end
  
  # You can pass link text with embedded country name which will be automatically expanded with short_country_name
  # E.g., "Click here to go to the site __country_name__" becomes "Click here to go to the site US"
  def country_link(locale, link_text=nil, link_path=nil)
      link_path ||= method(:country_root_url)
      country_name = I18n.t(:short_country_name,:locale => locale)
      link_text ||= country_name
      link_text.gsub!("__country_name__", country_name)
      country_code = I18n.t(:country_code,:locale => locale)
      ActionController::Base.helpers.link_to(link_text, link_path.call(:locale => country_code ))
  end
  
  def all_country_flag_links(path, options={})
        country_code_pfx = country_code_prefix(path)
 
        exclude = options[:exclude]
        country_codes = Constants::COUNTRIES.keys() 
       
        links=[]
       
        Constants::COUNTRIES.each_key do |country_code| # country_code like uk
        locale_ = Constants::COUNTRIES[country_code] # locale_ like en-GB
        unless locale_ == exclude.to_s
            # The following code is generic code for replacing one country scope by another.  
            # It can be extracted and reused when needed elsewhere
            new_path = String.new(path)
            if country_code_pfx
              if country_code_pfx[-1] != '/' # e.g., match /us
                end_idx = 3
              else  
                end_idx = 4 # e.g., match /us/about
              end
            else #No country code prefix, e.g. match the root url / or /about
              end_idx = 1 
            end
        
            new_path[0...end_idx] = "/#{country_code}/"
           
            short_country_name = I18n.t(:short_country_name, :locale =>locale_)
            #img = image_tag("flags/#{country_code}_flag.png", :alt => short_country_name)
            link = link_to(short_country_name, new_path, class: short_country_name)
            links << "<li>"+link+"</li>"
          end
      end 
      
      return raw "<ul class='drop-down'>#{links.inject{|acc, link|acc+link}}</ul>"
   end
   
   
   def country_code_prefix(path)
      country_codes = Constants::COUNTRIES.keys()
      matched  = country_codes.map { |country_code|  %r|^/#{country_code}/?|.match(path) }.find{|match|match}
      return matched.nil? ? nil :matched.to_s
   end
   
  
  
  def html_inspect(obj)
    obj.inspect.split(/\n/).map{|line|h(line)}.join("<br>").html_safe
  end
  
  def distance_of_time_in_days_ago(date)
    return "Today" if date > 1.day.ago
    return "Yesterday" if date > 2.day.ago
    return "#{distance_of_time_in_words_to_now(date, false)} ago"
  end
end
