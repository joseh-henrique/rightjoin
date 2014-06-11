class CompanyRatingsController < ApplicationController
  before_filter :init_employee_user
  before_filter :correct_user
  before_filter :strip_params
  
  def create
    @rating = CompanyRating.new(params)
    @rating.save!
    
    Reminder.create_event!(@rating.id, Reminder::COMPANY_RATED_ACTION)
    
    flash_message(:notice, "Thanks, we'll use the feedback to improve our job-matching.")
    redirect_to user_path(current_user, :locale => current_user.country_code)
    
  rescue Exception => e
    logger.error e
    flash_message(:error, Constants::ERROR_FLASH)
    redirect_to user_path(current_user, :locale => current_user.country_code)
  end  
  
  def correct_user
    deny_access jobs_path unless signed_in?
    
    unless current_user?(User.find(params[:user_id]))
      flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
      redirect_to user_path(current_user, :locale => current_user.country_code)
    end
    
    rescue Exception => e
      flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
      redirect_to jobs_path
  end
end
