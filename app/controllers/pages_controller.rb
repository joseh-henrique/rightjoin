class PagesController < ApplicationController
  include ApplicationHelper
  
  before_filter :init_employee_user, :only => [:root, :welcome, :privacy, :faq, :jobs, :register]
  before_filter :init_employer_user, :only => [:employer_welcome, :employer_get_started, :employer_privacy, :employer_faq, :employer_search]
  before_filter :add_locale_flash, :only =>[:register, :employer_get_started]
  

  def index
    init_employer_user
    if signed_in?
      flash.keep
      redirect_to(employer_path(current_user))
    else
      init_employee_user
      if signed_in?
        flash.keep
        redirect_to(jobs_path(:locale => current_user.country_code))
      end
    end
    
    unless performed?
      @current_page_info = PageInfo::INDEX
      render 'pages/index'
    end
  end
  
  def welcome
    @current_page_info = PageInfo::INDEX
    render 'pages/index'
  end  
  
  ###############################################################
  # employees
  def register
    if signed_in?
      flash.keep
      redirect_to(edit_user_path(current_user, :locale => current_user.country_code))
    else
      @user = User.new
      @current_page_info = PageInfo::REGISTER
      
      fyiscore = params[:fyiscore]# TODO The following is for the quiz and can be deleted
      if !fyiscore.nil? && fyiscore.to_i.between?(0, 5)
        flash_now_message(:notice, "We've filled out some of the form for you, using your quiz answers.")
        
        @defaults = {}
        @defaults[:no_years] = params[:yearsinjob].to_i
        # Get current job from radio buttons, but if "other" radio button was chosen, get value from field. 
        @defaults[:current_job] = params[:current_job]
        if @defaults[:current_job] == Constants::OTHER_JOB
          @defaults[:current_job] = params[:currentposition]
        end  
        @defaults[:wanted_job] = params[:wantedposition]
        @defaults[:wanted_job] ="" if @defaults[:wanted_job] = Constants::OTHER_JOB
        @defaults[:salary] = params[:wantedsalary].to_i
        @defaults[:reqirements] = read_requirements_from_quiz
      end
    end    
  end

  def privacy
    @current_page_info = PageInfo::PRIVACY
  end
  
  def faq
    @current_page_info = PageInfo::FAQ
  end
  
  def jobs
    begin
      search_jobs
    rescue Exception => e
      logger.error e
      flash_now_message(:error, Constants::ERROR_FLASH)
    ensure
      @current_page_info = PageInfo::JOBS
      render 'pages/jobs'
    end
  end
  
  ###############################################################3  
  # employers
  def employer_welcome
    if signed_in?
      flash.keep
      redirect_to(employer_path(current_user))
    else
      @current_page_info = PageInfo::EMPLOYER_WELCOME
      render 'pages/employer/welcome'
    end
  end
  
  def employer_get_started
    if signed_in?
      flash.keep
      redirect_to(employer_path(current_user))
    else
      @employer = Employer.new
      @current_page_info = PageInfo::EMPLOYER_GET_STARTED
      
      render 'pages/employer/get_started'
    end    
  end
  
  def employer_privacy
    @current_page_info = PageInfo::EMPLOYER_PRIVACY
    render 'pages/privacy'
  end
  
  def employer_faq
    @current_page_info = PageInfo::EMPLOYER_FAQ
    render 'pages/employer/faq'
  end
  
  def engineers
    search_users
    
    rescue Exception => e
      logger.error e
      flash_now_message(:error, Constants::ERROR_FLASH)
    ensure
      @current_page_info = PageInfo::ENGINEERS
      render 'pages/employer/search'
  end
  
  def employer_search
    search_users
    
    rescue Exception => e
      logger.error e
      flash_now_message(:error, Constants::ERROR_FLASH)
    ensure
      @current_page_info = PageInfo::EMPLOYER_SEARCH
      render 'pages/employer/search'
  end

private
    def read_requirements_from_quiz
      res = []
      (1..7).each do |i|
        res << params["missing#{i}"] unless params["missing#{i}"].nil?
      end
      (1..7).each do |i|
        res << params["keeps#{i}"] unless params["keeps#{i}"].nil?
      end
      
      res.uniq
    end
    
    def add_locale_flash
      is_user_valid = true
      unless signed_in?
        i18n_country_name = I18n.t(:short_country_name )
        actual_locale = LocationUtils::locale_by_ip(request.remote_ip, :unknown)
        if actual_locale == :unknown
          flash_now_message(:error, 
          "You've hit the #{i18n_country_name} site. Please choose your country at top-left, or  
				  #{uservoice_contact_link("drop us a line")}, and we'll let you know when we add support for your country.")
          is_user_valid = false
        elsif actual_locale != I18n.locale
          actual_country_link = country_link(actual_locale, "switch to the __country_name__ site here")
          flash_now_message(:notice, "You've hit the #{i18n_country_name} site. You can #{actual_country_link}.")
        end
      end
      return is_user_valid
    end
end
