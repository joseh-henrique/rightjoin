class EmployersController < ApplicationController
  include UsersControllerCommon
    
  before_filter :strip_params, :only => [:create, :verify, :update, :forgot_pw, :change_pw, :unsubscribe, :update_work_with_us_widget_config]
  before_filter :init_employer_user, :except => [:we_are_hiring, :ping, :work_with_us_tab, :work_with_us_test]
  before_filter :correct_user, :only => [:show, :edit, :update, :configure_work_with_us_widget, :update_work_with_us_widget_config]
  before_filter :add_verif_flash, :only =>[:show, :edit]
  before_filter :init_join_us_widget, :only =>[:we_are_hiring, :ping]

  # Execute initial signup request from main form
  def create
    @employer = Employer.new(params)
    @employer.password = @employer.random_pw()
    
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
    url= employer_welcome_url(:locale => country_code)

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
      flash_now_message(:notice, "Please review the candidate pings below, and pass some on to your employees for a chat.")  
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
    current_user.update_attributes(params)
    
    raise "A plan wasn't selected" if params[:tier].nil?
    tier = params[:tier]
    if current_user.current_plan.tier != tier
      plan = current_user.employer_plans.build(:tier => tier, :monthly_price => Utils::monthly_price(tier))
      plan.save!
    end
    
    redirect_to employer_path(current_user)
    flash_message(:notice, "Employer profile updated")
    
    rescue Exception => e
      logger.error e
      flash_message(:error,Constants::ERROR_FLASH)
      redirect_to edit_employer_path(current_user)
  end
 
  def change_pw
     do_change_pw Employer
  end
  
  def init_join_us_widget
    @infointerview = nil
    @job = nil
    @other_jobs = []
    @colors = params[:colors] || ""
    
    employer = Employer.find_by_ref_num(params[:refnum])
    @job = employer.active_jobs.find_by_id(params[:job]) unless params[:job].blank?
    
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
  rescue Exception => e
    logger.error e
    render text: "Error, cannot set up widget."  
  end
  
  def we_are_hiring
    @current_page_info = PageInfo::WE_ARE_HIRING_WIDGET
    
    render 'we_are_hiring/widget', :layout => "widget_layout" 
  rescue Exception => e
    logger.error e
    render text: "Error, cannot set up widget."  
  end
  
  def ping
    @current_page_info = PageInfo::WE_ARE_HIRING_WIDGET
    
    # check if user is signed in
    auth = current_auth(Constants::REMEMBER_TOKEN_INFOINTERVIEW)
    unless auth.nil?
      @infointerview = Infointerview.new
      @infointerview.job_id = @job.id
      @infointerview.auth = auth

      if signed_in?
        @infointerview.email = current_user.email
        @infointerview.first_name = current_user.first_name
        @infointerview.last_name = current_user.last_name
        @infointerview.user_id = current_user.id
      end
      
      @infointerview.email ||= auth.email
      @infointerview.first_name ||= auth.first_name
      @infointerview.last_name ||= auth.last_name
    end
    
    render 'we_are_hiring/widget', :layout => "widget_layout" 
  rescue Exception => e
    logger.error e
    render text: "Error, cannot set up widget."      
  end
  
  # process the command to auto-reset pw  
  def forgot_pw
    do_forgot_pw Employer
  end
  
  def unsubscribe
    do_unsubscribe Employer
  end
  
  def configure_work_with_us_widget
    @current_page_info = PageInfo::EMPLOYER_CONFIGURE_WORK_WITH_US_WIDGET
    @employer = current_user
    @employer.join_us_widget_params_map ||= ""
    render 'configure_work_with_us_widget'
  end
  
  def update_work_with_us_widget_config
    current_user.join_us_widget_params_map = params[:config]
    current_user.save!
    
    render :nothing => true, status: :ok
  rescue Exception => e
    logger.error e
    render :nothing => true, status: :forbidden    
  end
  
  def work_with_us_tab
    refnum = params[:refnum]
    host = params[:host]

    @employer = Employer.find_by_ref_num(refnum)
    
    # Track widget usage heartbeat every 12 hours. Exclude our own sites, which are not relevant to tracking customer usage.
    our_sites = ["www.#{Constants::FIVEYEAR_ITCH_SITENAME.downcase}", "localhost", "fyistage.herokuapp.com", "www.#{Constants::SITENAME_LC}", "www.#{Constants::SHORT_SITENAME.downcase}.co.il", "#{Constants::SHORT_SITENAME.downcase}.herokuapp.com"]
    unless  our_sites.include?(host.to_s.downcase)
      now = Time.parse(ActiveRecord::Base.connection.select_value("SELECT CURRENT_TIMESTAMP"))
      if @employer.join_us_widget_heartbeat.nil? || now - @employer.join_us_widget_heartbeat >= 12.hours
        @employer.update_attribute(:join_us_widget_heartbeat, now)
      end
    end
    
    render 'employers/work_with_us_tab.js.erb', :layout => false
    
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
end
