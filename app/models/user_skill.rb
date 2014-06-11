class UserSkill < ActiveRecord::Base
  belongs_to :user
  belongs_to :skill_tag
  
  LEARNER = 1
  PROFESSIONAL = 5
  EXPERT = 10
  
  # seniority should be validated on-save, but there may be some older values, so for now this is just for warnings
  def self.validate(seniority)
    [EXPERT, PROFESSIONAL, LEARNER].include? seniority 
  end
  
  def self.seniority_s(seniority)
    if seniority <=3 # Canonical value is 1 
      "Learner"
    elsif seniority <=6 # Canonical value is 5
      "Professional"
    else # Canonical value is 10
      "Expert"
    end
 end
end
