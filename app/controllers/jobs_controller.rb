class JobsController < ApplicationController
  before_filter :strip_params, :only => [:create, :update, :search, :copy_properties]
  before_filter :init_employee_user, :only => [:search]
  before_filter :init_employer_user, :except => [:search]
  before_filter :correct_employer, :except => [:search]
  
  def new
    @current_page_info = PageInfo::EMPLOYER_NEW_POSTING
    @job = Job.new
    @job.company_name = current_user.company_name
    @job.locale = I18n.locale.to_s
    @job.employer = current_user
    @job.join_us_widget_params_map = current_user.join_us_widget_params_map
    
    if @job.employer.enable_ping
      @job.benefits_list = ["Talk to your fellow developers.", "Click the ping button if you might be interested."]
    end
  end
  
  def copy_properties
    @current_page_info = PageInfo::EMPLOYER_NEW_POSTING
   
    @base_job = Job.find params[:copy_from][:jobid]
    
    raise "Not authorized" if @base_job.employer.id != current_user.id
    
    @job = Job.new
    @job.status = Job::DRAFT
    @job.company_name = @base_job.company_name
    @job.locale = @base_job.locale
    @job.employer = current_user
    
    @job.company_url = @base_job.company_url
    @job.logo_image_id = @base_job.logo_image_id
    
    @job.position = @base_job.position
    
    @job.allow_relocation = @base_job.allow_relocation
    @job.allow_telecommuting = @base_job.allow_telecommuting
     
    if  @base_job.locale == I18n.locale.to_s
        @job.location = @base_job.location
        @job.northmost = @base_job.northmost
        @job.southmost = @base_job.southmost
        @job.westmost = @base_job.westmost
        @job.eastmost = @base_job.eastmost
        @job.address = @base_job.address
        @job.address_lat = @base_job.address_lat
        @job.address_lng = @base_job.address_lng
    end
    
    @job.full_description = @base_job.full_description
    # copy all except url, which is always different
    
    @job.benefits_list = @base_job.benefits_list
    
    @job.image_1_id = @base_job.image_1_id
    @job.image_2_id = @base_job.image_2_id
    @job.image_3_id = @base_job.image_3_id
    @job.image_4_id = @base_job.image_4_id
    
    @job.video_url = @base_job.video_url
  
    @job.join_us_widget_params_map = @base_job.join_us_widget_params_map
    
    @job.tech_stack_list = @base_job.tech_stack_list
    
    @job.share_title = @base_job.share_title
    @job.share_description = @base_job.share_description
    @job.share_short_description = @base_job.share_short_description
    
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
    job.locale = I18n.locale.to_s
    job.display_order = Job::NORMAL_JOB_DISPLAY_RANK
    job.status = Job::DRAFT
    update_attrs(job)
    update_boards(job)
    update_global_join_us_style(job)

    Reminder.create_event!(job.id, Reminder::JOB_CREATED)
    
    add_flash_on_update_or_create
    
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
    @job.join_us_widget_params_map ||= current_user.join_us_widget_params_map
    
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
    @job = current_user.jobs_with_share_statistics_by_status(Job::PUBLISHED, Job::CLOSED).order("created_at DESC").find_by_id(params[:id])
    
    raise "Job position not found" if @job.nil?
    
    statuses = [Infointerview::NEW, Infointerview::ACTIVE_LEAD, Infointerview::CLOSED_BY_EMPLOYER]
    @infointerviews = @job.infointerviews.where(status: statuses).order("created_at DESC")
    
  rescue Exception => e
    logger.error e
    flash_message(:error,Constants::ERROR_FLASH)
    redirect_to employer_path(current_user)        
  end
  
  def update
    job = current_user.jobs.find(params[:id])
    update_attrs(job)
    update_boards(job)
    update_global_join_us_style(job)
    
    add_flash_on_update_or_create
    
    redirect_to employer_path(current_user, :anchor => "job#{job.id}")
    
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
  
  def add_flash_on_update_or_create
    case params[:commit].to_s.downcase
    when "save draft"
      flash_message(:notice, "You've saved a draft of your new job posting.")
    when "update draft"
      flash_message(:notice, "You've updated a draft of your job posting.")
    when "publish"
      if current_user.has_active_ambassadors?
        flash_message(:notice, "You've published your new job posting.")
      else 
        flash_message(:notice, "You've published your posting. Please invite team members to join you in connecting  to potential colleagues.")
      end
    when "update"
      flash_message(:notice, "You've updated your job posting.")
    end
  end

  def update_global_join_us_style(job)
    if Utils.to_bool(params["use-style-for-all"])
      job.employer.join_us_widget_params_map = params["join-us-config"]
      job.employer.save!
      
      Job.update_all( {:join_us_widget_params_map => nil}, {:employer_id => job.employer.id})
    end
  end

  def update_attrs(job)
    if params[:commit].to_s.downcase == "publish"
      job.status = Job::PUBLISHED
      job.published_at = Time.now
    end
    
    location_obj = LocationTag.find_or_create_by_params(params)
    raise ActiveRecord::RecordInvalid.new(location_obj) if location_obj.errors.any?
    
    position_str = params["position"]
    position_obj = PositionTag.find_or_create_by_name_case_insensitive(position_str)
    raise ActiveRecord::RecordInvalid.new(position_obj) if position_obj.errors.any?
    
    job.position = position_obj
    job.employer = current_user
    job.assign_all_location_attrs(location_obj, params["allow_telecommuting"] == "yes", params["allow_relocation"] == "yes")

    job.full_description = params["full_description"]
    job.company_name = params["company_name"]
    job.ad_url = params["ad_url"]
    job.company_url = params["company_url"]
    job.logo_image_id = params["company_logo_image_id"]
    
    benefits_param = params["benefits"]
    benefits_hash = Hash.from_url_params(benefits_param)
    job.benefits_list = benefits_hash.keys
    
    job.image_1_id = params["image_1_id"]
    job.image_2_id = params["image_2_id"]
    job.image_3_id = params["image_3_id"]
    job.image_4_id = params["image_4_id"]
    
    job.video_url = params["video_url"]
    
    job.address = params["address"]
    job.address_lat = params["address_lat"]
    job.address_lng = params["address_lng"]
    
    job.tech_stack_list = params["tech_stack_list"]
    
    job.join_us_widget_params_map = params["join-us-config"]
    
    job.share_title = params["share_title"]
    job.share_description = params["share_description"]
    job.share_short_description = params["share_short_description"]
    
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
