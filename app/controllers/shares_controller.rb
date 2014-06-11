class SharesController < ApplicationController
  include ApplicationHelper

  before_filter :strip_params, :only => [:increment_counter]
  
  def increment_counter
    setid = params[:setid]
    raise "Missing parameter" if setid.blank?
    
    setid.sub!(/^#/, '')
    
    share = Share.find_by_setid(setid)
    raise "Invalid parameter" if share.nil?
    
    share.increment!(:click_counter)
    
    # remember the share object, e.g. the referer
    store_obj_id_cookie(share, Constants::LEAD_REFERRAL_COOKIE, params = {:expires => 24.hour.from_now})
    
    res = {}
    if share.ambassador.status == Ambassador::ACTIVE
      link = share.ambassador.profile_link
      res = {:id => share.ambassador.id, :avatar_path => share.ambassador.avatar_path, :first_name => share.ambassador.first_name, :last_name => share.ambassador.last_name, :title => share.ambassador.title, :profile_link => link}
    end
    
    render :json => res
    
  rescue  Exception => e
    logger.error e
    render :nothing => true, status: :forbidden
  end
end
