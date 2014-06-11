class JobsController < ApplicationController
  before_filter :strip_params, :only => [:create, :update, :search, :copy_properties, :leads_set_seen]
  before_filter :init_employee_user, :only => [:search]
  before_filter :init_employer_user, :except => [:search]
  before_filter :correct_employer, :except => [:search]
  before_filter :add_verif_flash, :only =>[:new, :edit]
  
  def new
    @current_page_info = PageInfo::EMPLOYER_NEW_POSTING
    @job = Job.new
    @job.company_name = current_user.company_name
    @job.locale = I18n.locale.to_s
    @job.employer = current_user
  end
  
  def copy_properties
    @current_page_info = PageInfo::EMPLOYER_NEW_POSTING
    
    @base_job = Job.find params[:copy_from][:jobid]
    
    raise "Not authorized" if @base_job.employer.id != current_user.id
    
    @job = Job.new
    @job.company_name = @base_job.company_name
    @job.locale = @base_job.locale
    @job.employer = current_user
    
    @job.company_url = @base_job.company_url
    @job.logo_image_id = @base_job.logo_image_id
    
    @job.position = @base_job.position
    
    @job.allow_relocation = @base_job.allow_relocation
    @job.allow_telecommuting = @base_job.allow_telecommuting
    @job.location = @base_job.location
    @job.northmost = @base_job.northmost
    @job.southmost = @base_job.southmost
    @job.westmost = @base_job.westmost
    @job.eastmost = @base_job.eastmost

    @job.description = @base_job.description
    # copy all except url, which is always different
    
    @job.benefit1 = @base_job.benefit1
    @job.benefit2 = @base_job.benefit2
    @job.benefit3 = @base_job.benefit3
    @job.benefit4 = @base_job.benefit4
    
    @job.image_1_id = @base_job.image_1_id
    @job.image_2_id = @base_job.image_2_id
    @job.image_3_id = @base_job.image_3_id
    
    @job.address = @base_job.address
    @job.address_lat = @base_job.address_lat
    @job.address_lng = @base_job.address_lng
    
    @job.tech_stack_list = @base_job.tech_stack_list
    
    flash_now_message(:notice, "Job posting copied. You can now edit it.")
    
    render "jobs/new"
    
    rescue Exception => e
      logger.error e
      flash_message(:error, Constants::ERROR_FLASH)    
    redirect_to new_employer_job_path(current_user)
  end
  
  def create
    raise "Email must be verified to create a job posting" if current_user.status != UserConstants::VERIFIED
    
    job = Job.new
    job.status = Job::LIVE
    job.locale = I18n.locale.to_s
    job.display_order = Job::NORMAL_JOB_DISPLAY_RANK
    update_attrs(job)
    update_boards(job)

    Reminder.create_event!(job.id, Reminder::JOB_CREATED)
    
    if current_user.has_active_ambassadors?
      flash_message(:notice, "You've created a new job posting.")
    else 
      flash_message(:notice, "You've created a new job posting. Please invite team members to join you in connecting to their professional colleagues.")
    end
    
    redirect_to employer_path(current_user)
    
    rescue Exception => e
      logger.error e
      flash_message(:error, Constants::ERROR_FLASH)
      redirect_to new_employer_job_path(current_user)    
  end
  
  def destroy
    job = current_user.jobs.find(params[:id])
    job.shutdown!(Interview::CLOSED_BY_EMPLOYER)
    
    Reminder.create_event!(job.id, Reminder::JOB_CLOSED)

    flash_message(:notice, "Job position closed")
  rescue Exception =>e
    logger.error e
    flash_message(:error, "Failed to close this job position")
  ensure 
    redirect_to employer_path(current_user)
  end
  
  def edit
    @current_page_info = PageInfo::EMPLOYER_EDIT_POSTING
    @job = current_user.jobs.find(params[:id])
  
    raise "Job position not found" if @job.nil?
  
  rescue Exception => e
    logger.error e
    flash_message(:error, Constants::ERROR_FLASH)
    redirect_to employer_path(current_user)            
  end
  
  def recommended
    @current_page_info = PageInfo::EMPLOYER_RECOMMENDED
    @job = current_user.jobs.find(params[:id])
    
    raise "Job position not found" if @job.nil?
    
    @interviews = []
    @interviews = @job.interviews.find_all_by_status(Interview::RECOMMENDED) unless @job.closed?
    
  rescue Exception => e
    logger.error e
    flash_message(:error,Constants::ERROR_FLASH)
    redirect_to employer_path(current_user)        
  end
  
  def leads
    @current_page_info = PageInfo::EMPLOYER_LEADS
    @job = current_user.jobs.find(params[:id])
    
    raise "Job position not found" if @job.nil?
    
    @infointerviews = []
    unless @job.closed?
      statuses = [Infointerview::NEW, Infointerview::ACTIVE_LEAD, Infointerview::CLOSED_BY_EMPLOYER] # MP: now shows CLOSED_BY_EMPLOYER status
      @infointerviews = @job.infointerviews.where("infointerviews.status in (#{statuses.join(', ')})") 
    end
  rescue Exception => e
    logger.error e
    flash_message(:error,Constants::ERROR_FLASH)
    redirect_to employer_path(current_user)        
  end
  
  def leads_set_seen
    @job = current_user.jobs.find(params[:id])
    @job.infointerviews.update_all("status = #{Infointerview::ACTIVE_LEAD}", "status = #{Infointerview::NEW}")
    
    render :nothing => true, status: :ok
    
  rescue  Exception => e
    logger.error e
    render :nothing => true, status: :forbidden
  end  
  
  def update
    job = current_user.jobs.find(params[:id])
    update_attrs(job)
    update_boards(job)
   
    flash_message(:notice, "Job position updated")
    
    redirect_to employer_path(current_user)
    
    rescue Exception => e
      logger.error e
      flash_message(:error, Constants::ERROR_FLASH)
      redirect_to edit_employer_job_path(current_user, job, :locale => job.country_code)    
  end
  
  def search
      search_jobs
      @current_page_info = PageInfo::JOBS
 
      respond_to do |format|
        format.js { render 'search_results/success' }
        format.html { 
           redirect_to(jobs_path(:locale => I18n.t(:country_code, :locale => I18n.locale), :params=>params)) 
         }
      end
     rescue Exception => e
      logger.error e
      
      respond_to do |format|
        format.js { 
           flash_now_message(:error, Constants::ERROR_FLASH)
           render 'search_results/error'
        }
        format.html { 
            flash_message(:error, Constants::ERROR_FLASH)
            # Direct to base welcome path to avoid infinite loop back to this candidate-search page 
            redirect_to(jobs_path(:locale => I18n.t(:country_code, :locale => I18n.locale)) )
        }
      end
  end
  
private
  def update_attrs(job)
    location_obj = LocationTag.find_or_create_by_params(params)
    raise ActiveRecord::RecordInvalid.new(location_obj) if location_obj.errors.any?
    
    position_str = params["position"]
    position_obj = PositionTag.find_or_create_by_name(position_str)
    raise ActiveRecord::RecordInvalid.new(position_obj) if position_obj.errors.any?
    
    job.position = position_obj
    job.employer = current_user
    job.assign_all_location_attrs(location_obj, params["allow_telecommuting"] == "yes", params["allow_relocation"] == "yes")

    job.description = params["description"]
    job.company_name = params["company_name"]
    job.ad_url = params["ad_url"]
    job.company_url = params["company_url"]
    job.logo_image_id = params["company_logo_image_id"]
    
    job.benefit1 = params["benefit1"]
    job.benefit2 = params["benefit2"]
    job.benefit3 = params["benefit3"]
    job.benefit4 = params["benefit4"]
    
    job.image_1_id = params["image_1_id"]
    job.image_2_id = params["image_2_id"]
    job.image_3_id = params["image_3_id"]
    
    job.address = params["address"]
    job.address_lat = params["address_lat"]
    job.address_lng = params["address_lng"]
    
    job.tech_stack_list = params["tech_stack_list"]
    
    job.save!
  end
  
  def update_boards(job)
    board_names = params["board"]
    
    if board_names.blank?
      job.ads.destroy_all
    else
      # remove deleted
      job.ads.each {|ad|
        if board_names.has_key?(ad.board.name)
          board_names.delete(ad.board.name)
        else
          ad.destroy
        end
      }
      
      # add new
      board_names.each_key {|ad_name|
        board_to_add_to = Board.find_by_name(ad_name)
        ad = board_to_add_to.ads.build(:job_id => job.id)
        ad.save!
      }      
    end
  end
  
  def correct_employer
    uid_param = params[:employer_id]
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
