class SessionsController < ApplicationController
  include ApplicationHelper # for verified_flash_s
  before_filter :strip_params, :only => [:employee_signin, :employer_signin]
  before_filter :init_employee_user, :only => [:employee_signout]
  before_filter :init_employer_user, :only => [:employer_signout]

  def employee_signin
    email, pw = init_signin_params
    
    user = User.find_by_email(email)
    user ||= Employer.find_by_email(email) 
    
    unless user.nil?
      try_signin(user, pw)
    end
    
    if signed_in?
      if current_user.class == User
        redirect_back_or user_path(current_user, :locale => current_user.country_code)
      elsif current_user.class == Employer
        redirect_back_or employer_path(current_user)
      end
    else
      flash_message(:error, "Invalid email/password combination. Please try again.") if flash[:error].blank?
      redirect_to jobs_path 
    end    
    
  rescue Exception => e
    logger.error e
    flash_message(:error, Constants::ERROR_FLASH)
    redirect_to root_path 
  end
  
  def employee_signout
    do_destroy jobs_path
  end  
  
  def employer_signin
    email, pw = init_signin_params
    
    user = Employer.find_by_email(email)
    user ||= User.find_by_email(email)
    
    unless user.nil?
      try_signin(user, pw)
    end    
    
    if signed_in?
      if current_user.class == User
        redirect_back_or user_path(current_user, :locale => current_user.country_code)
      elsif current_user.class == Employer
        redirect_back_or employer_path(current_user)
      end
    else
      flash_message(:error, "Invalid email/password combination. Please try again.") if flash[:error].blank?
      redirect_to employer_welcome_path 
    end  
    
  rescue Exception => e
    logger.error e
    flash_message(:error, Constants::ERROR_FLASH)   
    redirect_to employer_welcome_path 
  end
  
  def employer_signout
    do_destroy employer_welcome_path
  end
  
  def init_signin_params
    email = params[:session][:email]
    if email.nil?
      raise "No email address provided."
    end
    email.downcase!
    
    pw = params[:session][:password]
    if pw.nil?
      raise "No password provided."
    end
    
    return email, pw
  end

private
  #Sign in from signin form
  def try_signin(user, pw)
    if user.authenticate(pw)
      if user.deleted? && user.class == Employer
        # This is an "Employer-deactivated" sceanrio. This will not occur in any normal flow. The employer object has been deleted. (This can only be done manually through the console or DB.)
        # However, we do NOT know that all  their job postings were deactivated (which is done through the unsubscribe method).
        flash_message(:error, "Your account has been deactivated. (You can reactivate&mdash;please #{ActionController::Base.helpers.link_to("contact us", "mailto:#{Constants::CONTACT_EMAIL}")}.)"  )
      else
        sign_in user
        
        if user.pending?
          user.verify
          Reminder.create_event!(current_user.id, user.class == User ? Reminder::USER_ACCOUNT_ACTIVATED : Reminder::EMPLOYER_ACCOUNT_ACTIVATED)
          flash_message(:notice, verified_flash_s)
        end
      end
    end
  end

  #Sign out
  def do_destroy(path)
    end_session
    flash.clear
    flash_message(:notice, "Signed out")
    redirect_back_or path
    clear_return_to
    
    rescue Exception => e
      logger.error e
      flash_message(:error, Constants::ERROR_FLASH)
      redirect_back_or path
  end
  
  def redirect_back_or(default)
    redirect_to(clear_return_to || default)
  end
end
