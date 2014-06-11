class Board < ActiveRecord::Base
  attr_accessible :description, :developer_text, :name, :order, :tag, :title
  
  has_many :ads, :dependent => :destroy
  
  validates :name, :presence => true
  validates :title, :presence => true
  validates :tag, :presence => true
  validates :description, :presence => true
  
  default_scope :order => 'boards.order DESC'
  
  def title_case
    ret = title
    ret[0] = ret[0].upcase unless ret.blank?
    return ret
  end
  #boards are configured, so these constants should be used only where a given board is hardcoded, as in welcome-page text 
  WORK_FROM_HOME = "work-from-home"
  OPEN_SOURCE = "open-source"
  MEANINGFUL_JOBS = "meaningful-jobs"
  BLEEDING_EDGE_TECH = "bleeding-edge-tech"
  STARTUPS = "startup"
  KEGERATOR = "kegerator"

end