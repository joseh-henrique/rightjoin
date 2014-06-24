class InfointerviewsController < ApplicationController
  before_filter :strip_params, :only => [:create, :close, :reopen, :delegate]
  before_filter :init_employee_user, :except => [:close, :reopen, :serve_avatar, :delegate]
  before_filter :init_infointerview_with_redirect, :only => [:close, :reopen]
  
  # ajax call
  def create
    auth = current_auth(Constants::REMEMBER_TOKEN_INFOINTERVIEW)
    if auth.nil? && !signed_in?
      render :nothing => true, status: :unauthorized
    else
      infointerview = Infointerview.new

      employer = Employer.find(params[:employer_id])
      infointerview = Infointerview.new

      job = employer.jobs.find(params[:job_id])
      infointerview.job_id = job.id  
      
      infointerview.email = params[:email]
      infointerview.first_name = params[:firstname]
      infointerview.last_name = params[:lastname]
      
      unless auth.nil?
        infointerview.auth = auth
        infointerview.profiles = auth.profiles_to_str
      end
      
      if signed_in?
        infointerview.user_id = current_user.id
        infointerview.profiles ||= current_user.resume
        infointerview.email ||= current_user.email
        infointerview.first_name ||= current_user.first_name
        infointerview.last_name ||= current_user.last_name
      end
      
      older_infointerviews = Infointerview.find_by_job_id_and_email(infointerview.job_id, infointerview.email)
      
      if older_infointerviews.nil? # silently ignore repeated pings from the same user to the same job
        infointerview.save!
        
        begin
          Reminder.create_event!(infointerview.id, Reminder::NEW_LEAD)
          
          share = get_obj_id_cookie(Share, Constants::LEAD_REFERRAL_COOKIE)
          if share && employer.id == share.job.employer_id # not necessarily the same job, but must be the same employer
            share.increment!(:lead_counter)
            infointerview.referred_by = share.ambassador_id
            infointerview.save!
          end
        rescue Exception => e # report and ignore
          logger.error e
        end
      end

      render :nothing => true, status: :ok
    end
  rescue ActiveRecord::RecordInvalid # likely because of the missing fileds in the user profile
    render :nothing => true, status: :internal_server_error
  rescue Exception => e 
    logger.error e
    render :nothing => true, status: :forbidden
  end
  
  def close
    @infointerview.status = Infointerview::CLOSED_BY_EMPLOYER
    @infointerview.save!
    
    flash_message(:notice, "You have closed a lead.")
    
    redirect_to leads_employer_job_path(current_user, @infointerview.job, :locale => @infointerview.job.country_code)
  rescue Exception => e
    logger.error e
    flash_message(:error, Constants::ERROR_FLASH)
    redirect_to employer_path(current_user)
  end
  
  def serve_avatar
    ref_num = params[:refnum]
    infointerview = Infointerview.find_by_ref_num(ref_num)
    raise "Lead wasn't found or is invalid" if infointerview.nil?
    
    auth = infointerview.auth
    if !auth.nil? && !auth.avatar.blank? && !auth.avatar_content_type.blank?
      response.headers['Cache-Control'] = 'public, max-age=300' unless params[:timestamp].blank?
      send_data(auth.avatar, :type => auth.avatar_content_type, :filename => "#{infointerview.id}", :disposition => "inline")
    else
      send_file "#{Rails.root}/public/no-avatar.png", :type => "image/png", :disposition => "inline"
    end
    
  rescue Exception => e
    logger.error e
    send_file "#{Rails.root}/public/no-avatar.png", :type => "image/png", :disposition => "inline"
    
  end
  
  def reopen
    @infointerview.status = Infointerview::ACTIVE_LEAD
    @infointerview.save!
    
    flash_message(:notice, "You have reopened a lead.")
    
    redirect_to leads_employer_job_path(current_user, @infointerview.job, :locale => @infointerview.job.country_code)
  rescue Exception => e
    logger.error e
    flash_message(:error, Constants::ERROR_FLASH)
    redirect_to employer_path(current_user)
  end  
  
  def delegate
    init_infointerview
    ambassador = Ambassador.find(params[:ambassador_id])
    followup = ambassador.followups.build(:infointerview => @infointerview)
    followup.save!
    
    msg = FyiMailer.create_delegate_infointerview_email(followup)
    Utils.deliver msg
    
    render :nothing => true, status: :ok
    
  rescue Exception => e
    render :nothing => true, status: :forbidden
  end  
  
private
  def init_infointerview_with_redirect
    init_infointerview
 
  rescue Exception => e
    logger.error e
    flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
    if signed_in?
      redirect_to employer_path(current_user)
    else
      redirect_to employer_welcome_path
    end    
  end
  
  def init_infointerview
    @infointerview = Infointerview.find params[:id]
    
    init_employer_user
    
    raise "Employer must be signed in" unless signed_in?
    raise "Employer mismatch" unless @infointerview.job.employer_id == current_user.id    
  end
end
