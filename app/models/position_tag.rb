class PositionTag < ActiveRecord::Base  
  validates :name, :presence => true, :length => { :maximum => 60 }
  validates_uniqueness_of :name, :case_sensitive => false
  has_many :users_with_current_pos, :dependent => :destroy, :foreign_key => 'current_position_id'
  has_many :users_with_wanted_pos, :dependent => :destroy, :foreign_key => 'wanted_position_id'
  has_many :jobs, :dependent => :destroy
  belongs_to :family_position, :class_name => 'PositionTag', :dependent => :destroy, :foreign_key => 'family_id'
  
  @@autocomplete = nil
  
  def self.find_or_create_by_name_case_insensitive(name)
    obj = PositionTag.where("lower(name) = ?", name.downcase).limit(1).first
    if obj.nil?
      obj = PositionTag.create(name: name)
    elsif obj.name != name && obj.priority == 0
      obj.update_attributes(name: name)
    end
    
    return obj
  end
  
  def self.find_by_name_case_insensitive(name)
    PositionTag.where("lower(name) = ?", name.downcase).limit(1).first
  end
  
  def self.popular_for_role(role_tag_name = "", limit = 8)
    Rails.cache.fetch("role_popular_for_role#{role_tag_name}#{limit}", :expires_in => 3.days) do
      position_condition = role_tag_name.blank? ? "" : "and users.current_position_id = (select position_tags.id from position_tags where " + sanitize_sql(["lower(position_tags.name) = '%s'", role_tag_name.downcase]) + ")"
      PositionTag.find_by_sql( 
        "  select position_tags.id, position_tags.name, position_tags.priority, count(position_tags.id) as resnum
        from position_tags
          inner join users
          on users.wanted_position_id = position_tags.id
        where position_tags.priority > 0 #{position_condition}
          group by position_tags.id, position_tags.name, position_tags.priority
          order by resnum desc
          limit #{limit}"
        )
    end
  end
  
  def self.all_approved_sorted_by_popularity
    PositionTag.find_by_sql( 
      "select position_tags.id, position_tags.name, position_tags.priority, count(position_tags.id) as resnum
      from position_tags
        left outer join users
        on users.wanted_position_id = position_tags.id
      where position_tags.priority > 0 
        group by position_tags.id, position_tags.name, position_tags.priority
        order by resnum desc"
      )
  end
  
  def self.autocomplete
    if @@autocomplete.nil? || @@autocomplete.created_at.since(3.days) < Time.now # reload every 3 days
      @@autocomplete = Autocomplete.new all_approved_sorted_by_popularity
    end
    @@autocomplete
  end  
  
  def self.add_position_to_group(what_position_name, to_position_name)
    what_position = PositionTag.where("lower(name) = '?'", what_position_name.downcase)
    to_position = PositionTag.where("lower(name) = '?'", to_position_name.downcase)
  
    if what_position.nil?
      raise "Unknown position \"#{what_position_name}\""
    elsif to_position.nil?
      raise "Unknown position \"#{to_position_name}\""
    else
      if to_position.id.nil?
        raise "\"#{to_position_name}\" has no group"
      else
        family_position_obj = PositionTag.find_by_id(to_position.id)
        if family_position_obj.nil?
          raise "Unknown position #{to_position.id}"
        else
          puts "Adding \"#{what_position.name}\" to \"#{family_position_obj.name}\" group"
          what_position.update_attribute(:family_id, family_position_obj.id)
        end
      end
    end
  end
end
