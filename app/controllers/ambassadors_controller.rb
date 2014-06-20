require 'net/http'

class AmbassadorsController < ApplicationController
  before_filter :strip_params, :only => [:update, :create, :share]
  before_filter :init_employer_user, :only => [:destroy]
  before_filter :correct_employer, :only => [:destroy]
  
  before_filter :set_ambassador_check_valid, :only => [:edit, :show, :update, :share]

  layout "team_layout" 
   
  AmbassadorsController::MAX_NUM_PROFILE_LINKS = 3
  
  def signin
    @employer = Employer.find_by_ref_num(params[:refnum])
    @current_page_info = PageInfo::AMBASSADOR_SIGNIN
    
    render 'ambassadors/signin' 
    
  rescue Exception => e
    logger.error(e)
    flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
    redirect_to employer_welcome_path
  end  
  
  def destroy
    @ambassador = Ambassador.find params[:id]
    raise "Wrong parameter" if @ambassador.employer.id != current_user.id
  
    @ambassador.status = Ambassador::CLOSED
    @ambassador.save!
    
    flash_message(:notice, "#{@ambassador.first_name}'s team member profile is now inactive.")
    
    redirect_to employer_path current_user
    
    rescue Exception => e
      logger.error e
      flash_message(:error, Constants::ERROR_FLASH)
      redirect_to employer_path current_user
  end
  
  def serve_avatar
    ref_num = params[:refnum]
    @ambassador = Ambassador.find_by_ref_num(ref_num)
    
    raise "Team member not found or invalid" if @ambassador.nil? || @ambassador.avatar.blank? || @ambassador.avatar_content_type.blank?

    response.headers['Cache-Control'] = 'public, max-age=300' unless params[:timestamp].blank?
    send_data(@ambassador.avatar, :type => @ambassador.avatar_content_type, :filename => "#{@ambassador.id}", :disposition => "inline")
    
    rescue Exception => e
      logger.error e
      send_file "#{Rails.root}/public/no-avatar.png", :type => "image/png", :disposition => "inline"
  end
  
  def new
    employer = Employer.find(params[:employer_id])
    @auth = current_auth(Constants::REMEMBER_TOKEN_AMBASSADOR)
    if @auth.nil?
      flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
      redirect_to ambassadors_signin_path(employer.reference_num, :locale => nil)   
    else
      @ambassador = Ambassador.new
      @ambassador.employer_id = employer.id
      @ambassador.init_from_oauth!(@auth)
      
      @current_page_info = PageInfo::AMBASSADOR_CREATE
      render 'ambassadors/edit' 
    end
    
  rescue  Exception => e
    logger.error e
    flash_message(:error, Constants::ERROR_FLASH)
    if employer.nil?
      redirect_to employer_welcome_path
    else
      redirect_to ambassadors_signin_path(employer.reference_num, :locale => nil)   
    end    
  end
  
  def create
    employer = Employer.find(params[:employer_id])
    @auth = current_auth(Constants::REMEMBER_TOKEN_AMBASSADOR)
    if @auth.nil?
      flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
      redirect_to ambassadors_signin_path(employer.reference_num, :locale => nil)   
    else
      @ambassador = Ambassador.new
      @ambassador.employer_id = employer.id
      @ambassador.init_from_oauth!(@auth)
      @ambassador.status = Ambassador::ACTIVE
      
      update_params
      @ambassador.save!
      
      # update the employer
      new_msg = FyiMailer.create_ambassador_profile_updated_email(@ambassador)
      Utils.deliver new_msg      
      
      redirect_to employer_ambassador_path(@ambassador.employer, @ambassador, :locale => nil)
    end
    
  rescue  Exception => e
    logger.error e
    flash_message(:error, Constants::ERROR_FLASH)
    if employer.nil?
      redirect_to employer_welcome_path
    else
      redirect_to new_employer_ambassador_path(:employer_id => employer.id, :locale => nil)
    end    
  end
  
  def edit   
    @current_page_info = PageInfo::AMBASSADOR_CREATE
    render 'ambassadors/edit'
    
  rescue  Exception => e
    logger.error e
    flash_message(:error, Constants::ERROR_FLASH)
    redirect_to ambassadors_signin_path(@ambassador.employer.reference_num, :locale => nil)
  end
  
  def update
    update_params
    @ambassador.save!
    
    redirect_to employer_ambassador_path(@ambassador.employer, @ambassador, :locale => nil) 
    
  rescue  Exception => e
    logger.error e
    flash_message(:error, Constants::ERROR_FLASH)
    redirect_to edit_employer_ambassador_path(@ambassador.employer, @ambassador, :locale => nil) 
  end
  
  def share
    setid = params[:setid]
    network = params[:network]
    job_id = params[:job_id]
    raise "mising parameter" if setid.blank? || network.blank? || job_id.blank?
    
    unless @ambassador.shares.where(setid: setid, job_id: job_id).any?
      @ambassador.shares.build(:setid => setid, :network => network, :job_id => job_id)
      @ambassador.save!
    end
    
    render :nothing => true, status: :ok
    
  rescue  Exception => e
    logger.error e
    render :nothing => true, status: :forbidden
  end
  
  def show
    @current_page_info = PageInfo::AMBASSADOR_CREATE
    
    @job = nil
    unless params[:job].blank?
      @job = @ambassador.employer.active_jobs.find_by_id(params[:job])
    end
    @job ||= @ambassador.employer.active_jobs.first if @ambassador.employer.active_jobs.any?
    
    render 'ambassadors/show'
    
  rescue  Exception => e
    logger.error e
    flash_message(:error, Constants::ERROR_FLASH)
    redirect_to ambassadors_signin_path(@ambassador.employer.reference_num, :locale => nil)    
  end
  
private
  def update_params
      @ambassador.first_name = params[:firstname]
      @ambassador.last_name = params[:lastname]
      @ambassador.title = params[:title]
      @ambassador.email = params[:email]
      
      raise "Missing first name" if @ambassador.first_name.blank?
      raise "Missing last name" if @ambassador.last_name.blank?
      raise "Missing title" if @ambassador.title.blank?
      raise "Missing email" if @ambassador.email.blank?
  end

  def set_ambassador_from_params
    employer = Employer.find(params[:employer_id])
    @ambassador = Ambassador.find(params[:id])
    # Actually, if employer or ambassador are not found by ID, There will be an exception above rather than getting nil values here. So, the checks are not really needed. 
    raise "Error: Employer #{params[:employer_id]} not found" if  employer.nil?  
    raise "Error: Ambassador #{params[:id]} not found" if   @ambassador.nil?  
    raise "Error: Ambassador #{params[:id]} has employer #{@ambassador.employer.id} not #{ employer.id}" if  @ambassador.employer.id != employer.id
    
    return true
    
  rescue Exception => e
    logger.error(e)
    flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
    if employer.nil?
      redirect_to employer_welcome_path
    else
      redirect_to ambassadors_signin_path(employer.reference_num, :locale => nil)
    end
    
    return false
  end
  
  def set_ambassador_check_valid
    if set_ambassador_from_params()
      @auth = current_auth(Constants::REMEMBER_TOKEN_AMBASSADOR)
      if @auth.nil? || @auth.id != @ambassador.auth.id
        flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
        redirect_to ambassadors_signin_path(@ambassador.employer.reference_num, :locale => nil)
      elsif @ambassador.status == Ambassador::CLOSED
        flash_message(:error, "The employee profile is closed.") 
        redirect_to ambassadors_signin_path(@ambassador.employer.reference_num, :locale => nil)
      end
    end
  rescue Exception => e
    logger.error(e)
    flash_message(:error, Constants::ERROR_FLASH)
    redirect_to ambassadors_signin_path(@ambassador.employer.reference_num, :locale => nil)
  end  

  def correct_employer
    uid_param = params[:employer_id]
    redirect_to employer_welcome_path and return unless uid_param.is_integer?
    
    employer = Employer.find(uid_param)
    unless current_user?(employer)
      deny_access employer_welcome_path
    end
    
    rescue Exception => e
      logger.error(e)
      flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
      redirect_to employer_welcome_path
  end
  
end
