class Event < ActiveRecord::Base
  attr_accessible :ambassador_id, :channel, :employer_id, :ip, :job_id, :referer, :type
  

end
