class Followup < ActiveRecord::Base
  validates :infointerview_id, :presence => true
  validates :ambassador_id, :presence => true  
  
  belongs_to :infointerview
  belongs_to :ambassador
  
  NEW = 0
  CLOSED = 10  
  
  scope :only_active, where("status <> ?", Followup::CLOSED)
    
end
