class JobQualifierTag < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true, :length => { :maximum => 60 }
  has_many :user_job_qualifiers, :dependent => :destroy
  before_save { |tag| tag.name = tag.name.downcase.strip }  
  
  @@autocomplete = nil
  
  def self.all_approved_sorted_by_popularity
    SkillTag.find_by_sql( 
      "select job_qualifier_tags.id, job_qualifier_tags.name, job_qualifier_tags.priority, count(job_qualifier_tags.id) as resnum
      from job_qualifier_tags
        left outer join user_job_qualifiers
        on user_job_qualifiers.job_qualifier_tag_id = job_qualifier_tags.id
      where job_qualifier_tags.priority > 0 
        group by job_qualifier_tags.id, job_qualifier_tags.name, job_qualifier_tags.priority
        order by resnum desc"
      )
  end
  
  def self.autocomplete
    if @@autocomplete.nil? || @@autocomplete.created_at.since(3.days) < Time.now # reload every 3 days
      @@autocomplete = Autocomplete.new all_approved_sorted_by_popularity
    end
    @@autocomplete
  end  
end
