class InterviewsController < ApplicationController
  include ApplicationHelper

  before_filter :strip_params, :only => [:create]
  before_filter :init_employer_user, :only => [:create]
  before_filter :init_employee_user, :only => [:destroy]
  before_filter :user_is_recipient, :only=>[:destroy]
  
  def create
    @user_id = params[:interview][:user_id] # recipient, i.e. employee
    
    unless current_user.verified?#This should never happen because you can't create a job unless you are verified. 
      @display_error = "To ping candidates, first verify your account with the password we sent you."
      raise @display_error
    end
      
    job_id = params[:job][:id]
    job = Job.find(job_id)
    
    unless current_user?(job.employer)
      @display_error = Constants::NOT_AUTHORIZED_FLASH
      raise "Not authorized to modify this job posting"
    end 
  
    @interview = job.interviews.find_by_user_id(@user_id)
    if @interview.nil?
      @interview = Interview.new
      @interview.user_id = @user_id
      @interview.job_id = job.id
      @interview.employer_id = job.employer.id
    end
    
    partial_path = 'interviews/error'
    if params[:decision] == "yes"
      if job.matches?(User.find(@user_id))
        @interview.status = Interview::APPROVED # approved automatically
      else
        @interview.status = Interview::AWAITING_APPROVAL
      end
      
      # increment number of invites
      job.increment(:invites_counter)
      job.save!
      
      flash_now_message(:notice, "We'll ping the candidate so they can get in touch with you.")
      partial_path = 'interviews/create'
    else 
      @interview.status = Interview::CLOSED_BY_EMPLOYER
      partial_path = 'interviews/set_employer_not_interested'
    end
    @interview.save!

    respond_to do |format|
      format.js {
        render partial_path
      }
    end

  rescue => e
    logger.error e
		
    @display_error ||= Constants::ERROR_FLASH
    flash_now_message(:error, @display_error)
    respond_to do |format|
      format.js {
        render 'interviews/error'
      }
    end
  end 
  
  def show
    @current_page_info = PageInfo::INTERVIEWS
  end

  private
  
  def user_is_recipient
    interview_id = params[:id]
    @interview = Interview.find_by_id(interview_id)
    
    unless signed_in?
        deny_access jobs_path
        return
    end
        
    if @interview
      unless current_user? @interview.user
        flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
        redirect_to user_path(current_user, :locale => current_user.country_code)
      end
    else #No @interview obj with this ID found, e.g. a URL was constructed with 999999 as interview ID. Don't give an "internal error message". Act as if the user is just not authorized. 
      flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
      redirect_to user_path(current_user, :locale => current_user.country_code)  
    end
  end
end
