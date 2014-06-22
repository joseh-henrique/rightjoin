class UsersController < ApplicationController
  include UsersControllerCommon
  
  before_filter :strip_params, :only => [:create, :verify, :update, :forgot_pw, :change_pw, :set_status, :index, :unsubscribe]
  before_filter :init_employee_user, :except => [:index]
  before_filter :init_employer_user, :only => [:index]
  before_filter :correct_user, :only => [:show, :edit, :update, :set_status]
  before_filter :add_verif_flash, :only =>[:show, :edit, :index]
  before_filter :add_mandatory_fields_flash, :only =>[:show]
  
  def set_status
    ok = false
    new_status = params[:status]
    current_user.update_column(:status, new_status)
    current_user.save!
    ok = true
    
    rescue Exception => e
      logger.error e
      flash_message(:error, Constants::ERROR_FLASH)
    ensure
      if ok
        @user = current_user
        respond_to do |format|
          format.js {
            render "users/set_status"
        }
      end
    else
      render :js => "window.location.reload(true);"
    end
  end  
  
  # Execute  signup request from main form
  def create
		@user = User.new

		@user.email= params["email"]
    @user.password = @user.random_pw()
    @user.locale = I18n.locale.to_s
    
    begin
      @user.validate_email_field!
    rescue ActiveRecord::RecordInvalid => e
      e.record.errors.full_messages.each do | msg | 
        logger.error e
        flash_message(:error, msg)
      end
      redirect_to register_path
      return
    end
    
    update_listing @user # populate properties
    sign_in @user
    
    url = user_url(@user, :locale => @user.country_code)
    
    new_msg = FyiMailer.create_welcome_message(@user.email, @user.password, @user.locale, User.reason_to_verify, User.homepage_description, url, :employee)
    Utils.deliver(new_msg)
    
    redirect_to user_path(@user, :locale => @user.country_code)

    rescue Exception => e
      logger.error e
 
      flash_message(:error,Constants::ERROR_FLASH)
      redirect_to register_path
  end
  
  def show
    @user = current_user
    @current_page_info = PageInfo::HOME
  end
  
  # Called when entering password from the flash to verify account
  def verify 
    do_verify User
  end
  
  def edit
    @user = current_user
    @current_page_info = PageInfo::EDIT
  end  
  
  def unsubscribe
    do_unsubscribe User
  end
  
  def update
    err_flash_msg = "The email address is invalid or already in use."
    
    begin
      # update email
      current_user.email = params["email"]
      current_user.validate_email_field!
      err_flash_msg = Constants::ERROR_FLASH
      
      # populate properties    
      update_listing current_user
      flash_message(:notice, "Profile updated")
      redirect_to user_path(current_user, :locale => current_user.country_code)
      
      return
      
    rescue Exception => e
      logger.error e
    end
    
    flash_message(:error, err_flash_msg)
    redirect_to edit_user_path(current_user, :locale => current_user.country_code)
  end
 
  def change_pw
    do_change_pw User
  end
  
  # process the command to auto-reset pw  
  def forgot_pw
    do_forgot_pw User
  end
   
  def index
    search_users
    @current_page_info = PageInfo::EMPLOYER_SEARCH
    
    respond_to do |format|
        format.js { render 'search_results/success' }
        format.html { 
           redirect_to(employer_search_path(:locale => I18n.t(:country_code, :locale => I18n.locale), :params=>params)) 
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
            # Direct to welcome  path to avoid infinite loop back to this candidate-search page 
            redirect_to(employer_welcome_path(:locale => I18n.t(:country_code, :locale => I18n.locale)) )
        }
      end
  end
 
  private
   
    def update_listing(user)
      location_obj = LocationTag.find_or_create_by_params(params)
      raise ActiveRecord::RecordInvalid.new(location_obj) if location_obj && location_obj.errors.any?

      currentposition_str = params["currentposition"]
      currentposition_obj = PositionTag.find_or_create_by_name(currentposition_str)
      raise ActiveRecord::RecordInvalid.new(currentposition_obj) if currentposition_obj.errors.any?
      
      wantedposition_str = params["wantedposition"]
      wantedposition_obj = PositionTag.find_or_create_by_name(wantedposition_str)
      raise ActiveRecord::RecordInvalid.new(wantedposition_obj) if wantedposition_obj.errors.any?
      
      user.current_position = currentposition_obj
      user.wanted_position = wantedposition_obj
      user.wanted_salary = params["wantedsalary"]
      user.free_text = params["freetext"]
      user.first_name = params["firstname"]
      user.last_name = params["lastname"]
      user.contact_info = params["contactinfo"]
      user.resume = params["resume"]
      user.assign_all_location_attrs(location_obj, params["can_telecommute"], params["can_relocate"])
      user.aspiration = params["aspiration"]
      
      # Delete previous skills and job qualifiers
      unless user.new_record?
        user.user_skills.destroy_all
        user.user_job_qualifiers.destroy_all
      end

      user.save!
      
      job_qual_params = params["jobqualifiers"]
      jobqualifiers_hash = Hash.from_url_params(job_qual_params)

      jobqualifiers_hash.each_key {|key| 
        job_qualifier_obj = JobQualifierTag.find_or_create_by_name(key.strip)
        if job_qualifier_obj.errors.any?
          flash_message(:error, Constants::ERROR_FLASH) if log_model_errors job_qualifier_obj
        else
          one_user_job_qualifier = UserJobQualifier.new
          one_user_job_qualifier.user = user
          one_user_job_qualifier.job_qualifier_tag = job_qualifier_obj
          one_user_job_qualifier.save!          
        end
      }
      
      skills_hash = Hash.from_url_params(params["skills"])
      skills_hash.each {|key, value| 
        skill_obj = SkillTag.find_or_create_by_name(key.strip)
        if skill_obj.errors.any?
          flash_message(:error, Constants::ERROR_FLASH) if log_model_errors skill_obj
        else
          one_user_skill = UserSkill.new
          one_user_skill.skill_tag = skill_obj
          one_user_skill.user = user
          one_user_skill.seniority = value.strip
          one_user_skill.save!
        end
      }      
    end
  
    def correct_user
      uid_param = params[:id]
      redirect_to jobs_path and return unless uid_param.is_integer?
      
      user = User.find(uid_param)
      unless current_user?(user)
        deny_access jobs_path
      end
      
      rescue Exception => e
        flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
        redirect_to jobs_path
    end
end
