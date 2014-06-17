class SkillTag < ActiveRecord::Base  
  validates :name, :presence => true, :uniqueness => true, :length => { :maximum => 60 }
  has_many :user_skills, :dependent => :destroy
  before_save { |tag| tag.name = tag.name.downcase.strip }  
  
  @@autocomplete = nil
  
  def self.popular_for_role(role_tag_name = "", limit = 40)
    Rails.cache.fetch("skills_popular_for_role#{role_tag_name}#{limit}", :expires_in => 3.days) do
      condition = role_tag_name.blank? ? ""  : "and position_tags.name = " + sanitize_sql(["'%s'", role_tag_name])
      popular_with_condition(condition, limit)
    end
  end
  
  def self.popular_for_position_family(position_family_id, limit = 40)
    Rails.cache.fetch("popular_for_position_family#{position_family_id}#{limit}", :expires_in => 3.days) do
      condition = "and position_tags.family_id = #{position_family_id}"
      popular_with_condition(condition, limit)
    end
  end
  
  def self.popular_with_condition(condition, limit)
    SkillTag.find_by_sql( 
      "select skill_tags.id, skill_tags.name, skill_tags.priority, count(skill_tags.id) as resnum
      from skill_tags
        inner join user_skills
        on user_skills.skill_tag_id = skill_tags.id
        inner join users
        on user_skills.user_id = users.id
        inner join position_tags
        on users.wanted_position_id = position_tags.id
      where position_tags.priority > 0 and skill_tags.priority > 0 #{condition} and users.status = 1
        group by skill_tags.id, skill_tags.name, skill_tags.priority
        order by resnum desc
        limit #{limit}"
      )
  end  
  
  def self.all_approved_sorted_by_popularity
    SkillTag.find_by_sql( 
      "select skill_tags.id, skill_tags.name, skill_tags.priority, count(skill_tags.id) as resnum
      from skill_tags
        left outer join user_skills
        on user_skills.skill_tag_id = skill_tags.id
      where skill_tags.priority > 0 
        group by skill_tags.id, skill_tags.name, skill_tags.priority
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
