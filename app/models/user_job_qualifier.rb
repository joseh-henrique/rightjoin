class UserJobQualifier < ActiveRecord::Base
  belongs_to :user
  belongs_to :job_qualifier_tag 
end
