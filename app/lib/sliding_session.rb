class SlidingSession
  SLIDING_SESSION_COOKIE_NAME = "sliding_session"
  SLIDING_SESSION_TIMEOUT = 30.minutes
  
  def initialize(val)
    @value = val
  end
  
  def self.init_sliding_session(cookies, request)
    val = cookies.signed[SLIDING_SESSION_COOKIE_NAME]
    if val.nil?
      val = {:channel => Share::CHANNEL_OTHER, :referred_by => nil, :referer => request.referer, :ip => request.remote_ip, :visited_job_ids => [], :shared_job_ids => []}
    end
    
    return SlidingSession.new(val)
  end
  
  def write(cookies)
      cookie ||= {
         :value => @value,
         :expires => SLIDING_SESSION_TIMEOUT.from_now
      }
      cookies.signed[SLIDING_SESSION_COOKIE_NAME] = cookie   
  end
  
  def add_visited_job(job_id)
    @value[:visited_job_ids] = @value[:visited_job_ids] | [job_id] # ensures uniqness
  end
  
  def visited_job?(job_id)
    @value[:visited_job_ids].include?(job_id)
  end
  
  def add_shared_job(job_id, network)
    @value[:shared_job_ids] = @value[:shared_job_ids] | ["#{job_id}:#{network}"] # ensures uniqness
  end
  
  def shared_job?(job_id, network)
    @value[:shared_job_ids].include?("#{job_id}:#{network}")
  end
  
  def referer
    @value[:referer]
  end
  
  def ip
    @value[:ip]
  end
  
  # ambassador id
  def referred_by
    @value[:referred_by]
  end
  
  def referred_by=(referred_by_id)
    @value[:referred_by] = referred_by_id
  end
  
  def locale_from_ip=(locale)
    @value[:locale] = locale
  end
  
  def locale_from_ip
    @value[:locale]
  end
  
  def channel
    @value[:channel]
  end
  
  def channel=(channel)
    @value[:channel] = channel
  end
end
