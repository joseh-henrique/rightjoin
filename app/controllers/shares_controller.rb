class SharesController < ApplicationController
  include ApplicationHelper

  before_filter :strip_params, :only => [:log_impression]
  
  def log_impression
    res = {}
    
    job = Job.find(params[:job_id])
    referred_by = nil

    decoded_hash = Share.parse_hash(params[:hash])
    unless decoded_hash.nil?
      @sliding_session.channel = decoded_hash[:channel] if @sliding_session.channel == Share::CHANNEL_OTHER

      ambassador = Ambassador.find_by_id(decoded_hash[:ambassador_id])
      if ambassador && ambassador.employer_id == job.employer_id
        referred_by = ambassador
      end
    end
    
    unless referred_by.nil?
      @sliding_session.referred_by = referred_by.id if @sliding_session.referred_by.nil?
      if referred_by.status == Ambassador::ACTIVE
        res = {:id => referred_by.id, :avatar_path => referred_by.avatar_path, :first_name => referred_by.first_name, :last_name => referred_by.last_name, :title => referred_by.title, :profile_link => referred_by.profile_link}
      end
    end
    
    unless @sliding_session.visited_job?(job.id)
      impression_attrs = {:network => @sliding_session.channel, :job_id => job.id, :ambassador_id => @sliding_session.referred_by, :ip => @sliding_session.ip, :referer => @sliding_session.referer, :click_counter => 1}
      Share.create!(impression_attrs)
      @sliding_session.add_visited_job(job.id)
    end
    
    render :json => res
    
  rescue  Exception => e
    logger.error e
    render :nothing => true, status: :forbidden
  end
end
