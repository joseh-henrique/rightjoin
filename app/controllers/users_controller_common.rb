module UsersControllerCommon 
  include ApplicationHelper

    # Called when entering password from the flash to verify account
    def do_verify(user_class)
      ok = false
      if !signed_in? or !current_user?(user_class.find(params[:id]))
        # current user nil only if you open another window; sign  out there, then enter your password for verification
        flash_message(:error, "Please sign in to verify your account. Check your email for the password, or choose \"Forgot Password\" above.")
      else
        email = params[:user][:email]
        requested_user = user_class.find_by_email(email)
        raise "#{email} not found" if requested_user.nil?
        if requested_user!=current_user
          end_session
        else
          pw = params[:user][:password]
  
          if pw && current_user.authenticate(pw)
            sign_in current_user
            current_user.verify
            flash_clear
            flash_now_message(:notice, verified_flash_s)
            # TODO Sometimes, when verifying, there is a flash error-message which says "You have already deactivated". 
            # In that case, upon verifying, this flash message should be removed from the DOM.
            ok = true
            
            Reminder.create_event!(current_user.id, user_class == User ? Reminder::USER_ACCOUNT_ACTIVATED : Reminder::EMPLOYER_ACCOUNT_ACTIVATED)
          else
            flash_message(:error, "Invalid password. Please try again, or sign out and choose \u201CForgot Password.\u201D")
          end
        end
      end
    rescue Exception => e
      logger.error e
      flash_message(:error, Constants::ERROR_FLASH)
    ensure
      if ok
        @user = current_user
        respond_to do |format|
          format.js {
            render "sessions/verify"
          }
        end
      else
        respond_to do |format|
          format.js {
            render :js => "window.location.reload(true);"
          }
        end
      end
  end
  
  def do_change_pw(user_class)
    @err_msg = ""
    if signed_in? and current_user?(user_class.find(params[:id]))
      if current_user.pending?
        @user = nil
        raise Exception, "Account must be verified to change password. Please enter password below, or sign out and use \u201CForgot Password.\u201D"
      else
        @user = current_user
        usr_params = params[@user.class.to_s.downcase]# hash key is "user" or "employer"
        raise Exception, "No user information", caller unless usr_params
        @user.update_attributes!(usr_params)        
      end
    else # not signedin
      @user = nil
      raise Exception, "Must be signed in to change password. Please refresh and sign in."
  
    end
  rescue  ActiveRecord::RecordInvalid =>e
    logger.error e
    # We access user errors because in principle there may be several errors,
    # even though in practice, passwords-don't-match is the only one that will be seen.  
    if @user and @user.errors.any?
      @err_msg<<"\n" unless @err_msg.blank?
      @err_msg<<@user.errors.full_messages.join("\n")
    end
  rescue Exception => e# from the Exceptions above in this method
    logger.error e
    @err_msg<<e.to_s<<"\n"
  ensure
    respond_to do |format|
      format.js {
        render 'users/change_pw'
      }
    end
  end
 
 # process the command to auto-reset pw  
 def do_forgot_pw(user_class)
    @user_by_email = nil 
   
    email_param = params[:email]
    raise "No email address provided" if email_param.nil?
    
    email_param.downcase!
    
    if user_class == User
      @user_by_email = User.find_by_email(email_param)
      @user_by_email ||= Employer.find_by_email(email_param)
    else
      @user_by_email = Employer.find_by_email(email_param)
      @user_by_email ||= User.find_by_email(email_param)
    end
    
    rescue Exception => e
      logger.error e
      flash_message(:error, Constants::ERROR_FLASH)
    ensure
      send_forgot_password(@user_by_email)
  end
  
  def send_forgot_password(user)
    if user
        user.password = user.random_pw() 
        user.save!
        if user.class == User 
          url = jobs_url(:locale => user.country_code)
          intended_for = :employee
        else 
          intended_for = :employer
          country_code = I18n.t(:country_code, I18n.locale)
          url= employer_welcome_url(country_code) #  Note that employers do not have their own native locale 
        end
        new_msg = FyiMailer.create_forgot_pw_message( user.email, user.password, user.class.happy_get_going_text, url, intended_for)
        Utils.deliver(new_msg)
    end 
    # Whether the email address is found or not, we show the same output, so that attackers can't figure out what exists in the system.
    # This is good for security, but it might not be the right thing to do for usability. 
     
    respond_to do |format|
      format.js {
        render 'users/forgot_pw'
      }
    end  
  end
  
  def do_unsubscribe(user_class)
    country_code = I18n.t(:country_code, I18n.locale)
    premium_plan = false
    user = user_class.find_by_id(params[:id])#Use find_by_id to produce nil rather than error as opposed to find()
        
    if user_class == User 
      root_path = root_path(:locale => country_code)
      unsubscribe_path = unsubscribe_user_path(:locale => country_code, :id => params[:id], :ref => params[:ref])
    else # employer
      root_path = employer_welcome_path #  Note that employers do not have their own native locale 
      unsubscribe_path = unsubscribe_employer_path(:id => params[:id], :ref => params[:ref])
      premium_plan = user.current_plan.tier > Constants::TIER_FREE
    end
    

    if user.nil? || user.reference_num(true) != params[:ref]
      raise "Invalid unsubscribe URL. Please <a href='mailto:#{Constants::CONTACT_EMAIL}'>contact us</a> if you need help unsubscribing."
    else
      flash.clear
      clear_return_to
      
      if signed_in? and not current_user?(user)
        end_session
      end
     
      if user.deleted?#relevant only to candidate, not employer
        raise "Your account is already deactivated. (You can reactivate if you'd like.)" 
      else
        
        if request.get? #This is the first HTTP request; after clicking the link here, the user will do a second, POST request.e
          if user.employee? 
            txt = "Please <a href='#{unsubscribe_path}' data-method='post'>click here</a> to deactivate your account and unsubscribe. (You can reactivate later.)"
          else
            if premium_plan
              txt = "Please <a href='#{unsubscribe_path}' data-method='post'>click here</a> to cancel your premium plan, close all job postings, and unsubscribe."  
            else
              txt = "Please <a href='#{unsubscribe_path}' data-method='post'>click here</a> to close all job postings and unsubscribe."
            end
          end

          flash_message(:error, txt) 
        else #This is the second HTTP request; first the user made the GET request, and then approved that; and this is a POST request.
          user.unsubscribe
          if user.employee? 
            txt = "Thanks for using #{Constants::SHORT_SITENAME}. Your account was deactivated. (You can reactivate later.)"
          else
            if premium_plan
              txt = "Thanks for using #{Constants::SHORT_SITENAME}. We've cancelled your premium plan, closed all your job postings, and unsubscribed you." 
            else
              txt = "Thanks for using #{Constants::SHORT_SITENAME}. We've closed all your job postings and unsubscribed you."
            end
          end
          flash_message(:notice, txt)
        end
      end
    end
    
  rescue Exception => e
    flash_message(:error, e.message)
  ensure
    redirect_to root_path
  end
end
