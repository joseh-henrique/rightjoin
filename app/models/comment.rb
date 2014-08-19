class Comment < ActiveRecord::Base
  belongs_to :ambassador
  belongs_to :infointerview
  
  validates :infointerview_id, :presence => true
  validates :created_by, :presence => true
  validates :body, :presence => true
  validates :ambassador_id, :presence => true, :if => :created_by_ambassador?
  
  # newest first
  default_scope :order => 'comments.created_at DESC'
  
  CREATED_BY_SYSTEM = 0
  CREATED_BY_EMPLOYER = 10
  CREATED_BY_AMBASSADOR = 20  
  
  STATUS_NORMAL = 0
  STATUS_NEW = 10 # employer has not been notified yet, used for comments created by ambasadors only
  STATUS_NOT_SEEN = 20 # employer has not seen the comment yet, used for comments created by ambasadors only
  
  def created_by_ambassador?
    created_by == CREATED_BY_AMBASSADOR
  end
  
  def author_display_name
    res = "unknown"
    if created_by == CREATED_BY_SYSTEM
      res = "Update"
    elsif created_by == CREATED_BY_EMPLOYER
      employer = self.infointerview.employer
      res = "#{employer.first_name} #{employer.last_name}"
    elsif created_by == CREATED_BY_AMBASSADOR
      ambassador = self.ambassador
      res = "#{ambassador.first_name} #{ambassador.last_name}"
    end
    
    return res
  end
  
  def author_avatar_path
    res = "unknown"
    if created_by == CREATED_BY_SYSTEM
      res = ActionController::Base.helpers.asset_path("shared/system-avatar-48x48.png");
    elsif created_by == CREATED_BY_EMPLOYER
      res = ActionController::Base.helpers.asset_path("shared/business-user-avatar-48x48.png");
    elsif created_by == CREATED_BY_AMBASSADOR
      res = ambassador.avatar_path
    end
    
    return res    
  end
  
  def self.get_new_comments_from_ambassadors
    Comment.includes(:ambassador, :infointerview).where("ambassador_id is not null and status = ?", STATUS_NEW)
  end
  
  def self.create_system_comment!(infointerview_id, body, created_at = DateTime.now)
    c = Comment.new
    c.infointerview_id = infointerview_id
    c.body = body
    c.created_by = CREATED_BY_SYSTEM
    c.created_at = created_at
    c.save!
  end
end
