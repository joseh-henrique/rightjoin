class Ad < ActiveRecord::Base
  attr_accessible :board_id, :job_id
  
  validates :board_id, :presence => true
  validates :job_id, :presence => true
  
  belongs_to :job
  belongs_to :board
  
  default_scope :order => 'ads.created_at DESC'
  
  RENDERING_MODE_FULL = 0
  RENDERING_MODE_COMPACT = 1
end
