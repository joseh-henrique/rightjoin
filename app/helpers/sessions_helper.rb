module SessionsHelper
  def sign_in(user)
    unless signed_in? and current_user?(user)
      cookies.permanent[user.class.remember_token_key] = user.remember_token
      @current_user = user
    end
  end

  def signed_in?
    !@current_user.nil?
  end

  def current_user
    @current_user
  end
  
  def current_user?(user)
    user == @current_user
  end
  
  def end_session
    unless @current_user.nil?
      cookies.delete(@current_user.class.remember_token_key)
      @current_user = nil
    end
  end
  
  def deny_access(redirect_url)
    store_location
    flash_message(:error, "Please sign in above to access this page.")
    redirect_to redirect_url
  end
  
  def init_employee_user
    init_current_user User
  end
  
  def init_employer_user
    init_current_user Employer
  end  
  
  def init_current_user(model_class)
    @current_user = model_class.find_by_remember_token(cookies[model_class.remember_token_key])
  end
  
  def get_employee_user_by_session_cookie
    get_user_by_session_cookie User
  end
  
  def get_employer_user_by_session_cookie
    get_user_by_session_cookie Employer
  end  
  
  def get_user_by_session_cookie(model_class)
    model_class.find_by_remember_token(cookies[model_class.remember_token_key])
  end  
  
  #################################################################
  def store_location
    # store get requests only, tried for the first time
    if request.request_method_symbol() == :get && params[:tryonce] != "true" 
      location = request.fullpath + (request.fullpath.include?('?') ? '&' : '?') + "tryonce=true"
      session[:return_to] = location
    else
      clear_return_to
    end
  end  

  def clear_return_to
    goto = session[:return_to]
    session[:return_to] = nil
    goto
  end
  
  def store_obj_id_cookie(obj, remember_token, params = {})
    if obj.nil?
      cookies.delete(remember_token)
    else
      cookie = {
         :value => [obj.id, obj.created_at.to_i]
      }.merge(params)
      cookies.signed[remember_token] = cookie      
    end
  end
  
  def get_obj_id_cookie(model, remember_token)
    obj = nil
    id, obj_created = cookies.signed[remember_token]
    unless id.nil? || obj_created.nil?
      obj = model.find_by_id(id)
      if obj.nil? || obj.created_at.to_i != obj_created
        obj = nil
      end
    end
    return obj
  end
  
  def store_auth(auth, remember_token)
    store_obj_id_cookie(auth, remember_token)
  end
  
  def current_auth(remember_token)
    return get_obj_id_cookie(Auth, remember_token)
  end
end
