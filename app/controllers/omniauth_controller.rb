 
class OmniauthController < ApplicationController
     
   # NOTE: The auth_failure method is stored in omniauth initializer and so is not reloaded in development until the server is restarted.
 
   def auth_failure 
    token = session[:auth_tmp_token]
      type = session[:auth_tmp_type]
      
      session[:auth_tmp_token] = nil
      session[:auth_tmp_type] = nil
      
      if type == Constants::OAUTH_TYPE_INSIDER
        employer = Employer.find_by_ref_num(token)
        flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
        if employer
         redirect_to ambassadors_signin_path(employer.reference_num, :locale => nil)
        else # should not happen, but we cannot absolutely rely on the session value being set.
         redirect_to infointerview_error_path(:locale => nil)
        end
      elsif type == Constants::OAUTH_TYPE_CONTACT
        job = Job.find(token)
        flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
        if job
         redirect_to we_are_hiring_employer_path(job.employer.reference_num, :job => job.id)
        else
         raise Constants::NOT_AUTHORIZED_FLASH
        end      
      else 
        if session[:oauth_return_to]
          redirect_path =  session[:oauth_return_to] 
        else  # Should not occur, but we want to handle this  case.
          redirect_path =   employer_welcome_url(:locale => I18n.t(:country_code, I18n.locale) )
        end
        
       session[:oauth_return_to] = nil
       # It might make sense to show a flash message here as follows flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
       # Reasons not to:
       # 1. In the usual use case, the user got through authentication using G+ and then pushes the back button. It is reasonable that he goes back to the signin page.
       # From his perspective, he is not necessarily passing through the G+ OAuth page. So, nothing "unauthorized" is happening here/
       # 2. Chrome  does not rendeer the target of the redirect. It loads a cached page so the flash will not show. We can force rendering with a URL suffix like  + "?redirect=unauthorized" 
       session[:oauth_return_to] = nil
       redirect_to(redirect_path)
      end      
   end
   
   def login_with
     referrer = URI(request.referer).path # This will be a path like  /team/6418b5a/signin .
     session[:oauth_return_to] = referrer
     
     provider = params[:provider]
     session[:auth_tmp_token] = params[:token] 
     session[:auth_tmp_type] = params[:type]
     redirect_to "/auth/#{provider}" # redirect to omniauth auth
   end
  
  def callback
    auth = request.env["omniauth.auth"]
    
    token = session[:auth_tmp_token]
    type = session[:auth_tmp_type]
    
    session[:auth_tmp_token] = nil
    session[:auth_tmp_type] = nil
    
    if type == Constants::OAUTH_TYPE_INSIDER
      begin
        # this throws exception if employer refnum is invalid
        employer = Employer.find_by_ref_num(token)
        
        auth_obj = Auth.create_from_oauth!(auth)
        store_auth(auth_obj, Constants::REMEMBER_TOKEN_AMBASSADOR)
        
        ambassador = auth_obj.ambassadors.find_by_employer_id(employer.id)
        if ambassador.nil?
          redirect_to new_employer_ambassador_path(:employer_id => employer.id, :locale => nil) # new
        elsif ambassador.status == Ambassador::CLOSED
          ambassador.reactivate!
          flash_message(:notice, "Your team-member account has been re-activated") 
          redirect_to employer_ambassador_path(employer, ambassador, :locale => nil) # view
        else
          redirect_to employer_ambassador_path(employer, ambassador, :locale => nil) # view
        end
      rescue Exception => e
        logger.error e
        flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
        redirect_to ambassadors_signin_path(token, :locale => nil)
      end
    elsif type == Constants::OAUTH_TYPE_CONTACT
      # valid token is mandatory, show a standard error page if missing
      job = Job.find(token)
      begin
        auth_obj = Auth.create_from_oauth!(auth)
        store_auth(auth_obj, Constants::REMEMBER_TOKEN_INFOINTERVIEW)
      rescue Exception => e
        logger.error e
        flash_message(:error, Constants::NOT_AUTHORIZED_FLASH)
      ensure
        redirect_to ping_employer_path(job.employer.reference_num, :job => job.id)
      end
    else
      raise Constants::NOT_AUTHORIZED_FLASH
    end
  end
end

