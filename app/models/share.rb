class Share < ActiveRecord::Base
  validates :setid, :presence => true
  
  belongs_to :ambassador
  belongs_to :job
end
