class CompanyRating < ActiveRecord::Base
  attr_accessible :company_name, :ace_colleagues, :career_opportunitites, :impact, :learning_opportunitites, :relaxed_culture, :user_id, :worklife_balance, :workplace_perks
  validates :company_name, :presence => true
  
  belongs_to :user
  
  def inspect
    parts = [
    "--------- Company rating (id:#{self.id}) ---------",
    "** Created at #{self.created_at} (#{((Time.now - self.created_at)/(3600 * 24)).to_i} days ago)",
    "** Company #{self.company_name} rated by #{self.user.current_position_name} from #{self.user.all_location_parts.join(" / ")} (user_id: #{self.user_id})",
    "** Impact: #{self.impact}",
    "** Work-life balance: #{self.worklife_balance}",
    "** Career opportunitites: #{self.career_opportunitites}",
    "** Learning opportunitites: #{self.learning_opportunitites}",
    "** Workplace perks: #{self.workplace_perks}",
    "** Relaxed culture: #{self.relaxed_culture}",
    "** Ace colleagues: #{self.ace_colleagues}"        
    ]
    parts.join("\n").concat("\n")
  rescue Exception => e
    logger.error "Inspect failed for #{self.class}: #{e}"
    super.inspect    
  end  
end
