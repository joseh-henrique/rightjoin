class EmployerPlan < ActiveRecord::Base
  attr_accessible :employer_id, :monthly_price, :tier
  
  validates :employer_id, :presence => true
  validates :monthly_price, :presence => true
  validates :tier, :presence => true
  
  belongs_to :employer
  
  FREE = "Free"
  PRO = "Pro"
  ENTERPRISE = "Enterprise"
  
  def name
    name = FREE
    if self.tier == Constants::TIER_PRO
      name = PRO
    elsif self.tier == Constants::TIER_ENTERPRISE
      name = ENTERPRISE
    end
    return name
  end
end
