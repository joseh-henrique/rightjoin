class EmployersController < ApplicationController
  include UsersControllerCommon
    
  before_filter :strip_params, :only => [:create, :verify, :update, :forgot_pw, :change_pw, :unsubscribe]
  before_filter :init_employer_user, :except => [:we_are_hiring, :ping, :work_with_us_tab, :work_with_us_test]
  before_filter :correct_user, :only => [:show, :edit, :update, :configure_join_us_tab]
  before_filter :add_verif_flash, :only =>[:edit]
  before_filter :init_join_us_widget, :only =>[:we_are_hiring, :ping]
  after_filter :minimize_js_response, :only => :work_with_us_tab

  # Execute initial signup request from main form
  def create
    @employer = Employer.new(params)
    @employer.password = @employer.random_pw
    
    begin
      @employer.validate_email_field!
    rescue ActiveRecord::RecordInvalid => e
      e.record.errors.full_messages.each do | msg | 
        logger.error e
        flash_message(:error, msg)
      end
      redirect_to employer_get_started_path
      return
    end
    
    raise "A plan wasn't selected" if params[:tier].nil?
    
    @employer.save!
    
    tier = params[:tier]
    plan = @employer.employer_plans.build(:tier => tier, :monthly_price => Utils::monthly_price(tier))
    plan.save!
    
    sign_in @employer
    
    country_code = I18n.t(:country_code, I18n.locale) 
    url = employer_welcome_url(:locale => country_code)
    new_msg = FyiMailer.create_welcome_message(@employer.email, @employer.password, I18n.locale, Employer.reason_to_verify, Employer.homepage_description, url, :employer)
    Utils.deliver(new_msg)
    
    redirect_to new_employer_job_path(@employer, :board => params[:board].nil? ? "" : params[:board])
    
  rescue Exception => e
    logger.error e
    flash_message(:error,Constants::ERROR_FLASH)
    redirect_to employer_get_started_path
  end
  
  def show
    @current_page_info = PageInfo::EMPLOYER_HOME
    if params[:need_approvals]
      flash_now_message(:notice, "Please review the candidate pings below, and pass them on to your team members for a chat.")  
    end
  end
  
  # Called when entering password from the flash to verify account
  def verify 
    do_verify Employer
  end
  
  def edit
    @current_page_info = PageInfo::EMPLOYER_EDIT
    @employer = current_user
  end  
  
  def update
    if current_user.pending?
      current_user.password = current_user.random_pw
    end
    
    current_user.update_attributes(params)
    
    raise "A plan wasn't selected" if params[:tier].nil?
    tier = params[:tier]
    if current_user.current_plan.tier != tier
      plan = current_user.employer_plans.build(:tier => tier, :monthly_price => Utils::monthly_price(tier))
      plan.save!
    end
    
    if current_user.pending?
      country_code = I18n.t(:country_code, I18n.locale) 
      url = employer_welcome_url(:locale => country_code) #TODO This should be the employer dashbaord URL. But this welcome URL works 
      new_msg = FyiMailer.create_welcome_message(current_user.email, current_user.password, I18n.locale, Employer.reason_to_verify, Employer.homepage_description, url, :employer)
      Utils.deliver(new_msg)
    else
      flash_message(:notice, "Employer profile updated")    
    end
    
    redirect_to employer_path(current_user)
    
    rescue Exception => e
      logger.error e
      flash_message(:error,Constants::ERROR_FLASH)
      redirect_to edit_employer_path(current_user)
  end
 
  def change_pw
     do_change_pw Employer
  end
  
  def we_are_hiring
    @current_page_info = PageInfo::WE_ARE_HIRING_WIDGET
    
    render 'we_are_hiring/widget', :layout => "widget_layout" 
  rescue Exception => e
    logger.error e
    render 'we_are_hiring/error', :layout => false, :locals => {:message => "The posting could not be loaded."}
  end
  
  def ping
    @current_page_info = PageInfo::WE_ARE_HIRING_WIDGET
    
    # check if user is signed in
    auth = current_auth(Constants::REMEMBER_TOKEN_INFOINTERVIEW)
    unless auth.nil?
      @infointerview = Infointerview.new
      @infointerview.job_id = @job.id
      @infointerview.auth = auth
      
      @infointerview.email = auth.email
      @infointerview.first_name = auth.first_name
      @infointerview.last_name = auth.last_name
      
      unless @candidate.nil?
        @infointerview.email ||= @candidate.email
        @infointerview.first_name ||= @candidate.first_name
        @infointerview.last_name ||= @candidate.last_name
        @infointerview.user_id = @candidate.id
      end
    end
    
    render 'we_are_hiring/widget', :layout => "widget_layout" 
  rescue Exception => e
    logger.error e
    render 'we_are_hiring/error', :layout => false, :locals => {:message => "The posting could not be loaded."}
  end
  
  # process the command to auto-reset pw  
  def forgot_pw
    do_forgot_pw Employer
  end
  
  def unsubscribe
    do_unsubscribe Employer
  end
  
  def configure_join_us_tab
    @current_page_info = PageInfo::EMPLOYER_CONFIGURE_JOIN_US_TAB
    @employer = current_user
    render 'configure_join_us_tab'
  end
  
  def work_with_us_tab
    tab_expires_in = 1.month # default for unsupported locales
    
    refnum = params[:refnum]
    host = params[:host]

    @employer = Employer.find_by_ref_num(refnum)
    @activeJobsCount = 0
    
    # ensure jobs are shown for the actual locale
    if is_localhost?
      locale = Constants::LOCALE_EN.to_sym
    else
      locale = LocationUtils::locale_by_ip(request.remote_ip, :unknown_locale)
    end
    
    if locale != :unknown_locale
      I18n.locale = locale
      @activeJobsCount = @employer.active_jobs.where(locale: I18n.locale).count
      tab_expires_in = 15.minutes
    end
    
    # Track widget usage heartbeat every 12 hours. Exclude our own sites, which are not relevant to tracking customer usage.
    # Given our redirect setup, not all these are needed, but we may change the redirect setup.
    our_sites = [ 
        "www.#{Constants::SITENAME_LC}",
         "#{Constants::SHORT_SITENAME.downcase}.herokuapp.com",
        "localhost", 
        "fyistage.herokuapp.com",
        Constants::SITENAME_IL_LC,  
        "www.#{Constants::SITENAME_IL_LC}",
        "www.#{Constants::FIVEYEARITCH_SITENAME.downcase}", 
        Constants::SITENAME_LC
    ]

    if our_sites.include?(host.to_s.downcase)
      tab_expires_in = 0
    else
      now = Time.parse(ActiveRecord::Base.connection.select_value("SELECT CURRENT_TIMESTAMP"))
      if @employer.join_us_widget_heartbeat.nil? || now - @employer.join_us_widget_heartbeat >= 12.hours
        @employer.update_attribute(:join_us_widget_heartbeat, now)
      end
    end    
    
    render 'employers/work_with_us_tab.js.erb', :layout => false
    
    expires_in tab_expires_in, :public => false
    
  rescue Exception => e
    logger.error e
    render :text => "// #{Constants::ERROR_FLASH}".html_safe, :layout => false
  end
  
  def work_with_us_test
    @employer = Employer.find_by_ref_num(params[:refnum])
    render 'work_with_us_test', :layout => false
  rescue Exception => e
    flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
    redirect_to employer_welcome_path  
  end
   
  private
  
    def init_join_us_widget
      @infointerview = nil
      @job = nil
      @other_jobs = []
      @colors = params[:colors] || ""
      
      employer = Employer.find_by_ref_num(params[:refnum])
      @job = employer.active_jobs.find_by_id(params[:job]) unless params[:job].blank?
      
      @candidate = get_employee_user_by_session_cookie
      
      # used to emphasize the ambassador's picture in the widget when seen by himself
      @ambassador = nil
      auth = current_auth(Constants::REMEMBER_TOKEN_AMBASSADOR)
      unless auth.nil?
        ambassador = auth.ambassadors.find_by_employer_id(employer.id)
        if !ambassador.nil? && ambassador.status != Ambassador::CLOSED
          @ambassador = ambassador
        end
      end
      
      if @job.nil?
        @other_jobs = employer.active_jobs
        @job = @other_jobs.pop
      else
        @other_jobs.concat employer.active_jobs.select{|j| j.id != @job.id}
      end
      
      if @job.nil?
        render 'we_are_hiring/error', :layout => false, :locals => {:message => "The position is not active."}
      end
    rescue Exception => e
      logger.error e
      render 'we_are_hiring/error', :layout => false, :locals => {:message => "The posting could not be loaded."}
    end  
  
    def correct_user
      uid_param = params[:id]
      redirect_to employer_welcome_path and return unless uid_param.is_integer?
      
      employer = Employer.find(uid_param)
      unless current_user?(employer)
        deny_access employer_welcome_path
      end
      
      rescue Exception => e
        flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
        redirect_to employer_welcome_path
    end
    
    # minimize JS on the fly
    def minimize_js_response
      response.body = Uglifier.new.compile(response.body)
    end
end
