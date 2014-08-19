class CommentsController < ApplicationController
  include ApplicationHelper

  before_filter :strip_params, :only => [:create, :set_seen]
  before_filter :init_employer_user, :only => [:set_seen]
  
  # ajax request
  def create
    infointerview = Infointerview.find(params[:infointerview_id])
    body = params["comment"]["body"]
    display_for = nil
    
    employer_id = params[:employer_id].to_i
    ambassador_id = params[:ambassador_id].to_i
    
    # is employer valid
    if employer_id != 0
      init_employer_user
      if employer_id == current_user.id
        display_for = current_user
        current_user.create_comment!(infointerview.id, body)
      else
        raise Constants::NOT_AUTHORIZED_FLASH
      end
    end
    
    # is ambassador valid
    if ambassador_id != 0
      ambassador = Ambassador.find(ambassador_id)
      
      if infointerview.employer.id == ambassador.employer_id
        display_for = ambassador
        ambassador.create_comment!(infointerview.id, body)
      else
        raise Constants::NOT_AUTHORIZED_FLASH
      end
    end 
    
    raise Constants::ERROR_FLASH if display_for.nil? || infointerview.nil?
    
    render :partial => "comments/lead_comments", :locals => { :lead => infointerview, :display_for => display_for }, :layout => false
  rescue String => e
    logger.error e
    render :text => e, status: :internal_server_error
  rescue Exception => e
    logger.error e
    render :nothing => true, status: :internal_server_error
  end
  
  def set_seen
    infointerview = Infointerview.find(params[:infointerview_id])
    comment = infointerview.comments.find(params[:comment_id])
    
    if comment.status != Comment::STATUS_NORMAL # NORMAL means "seen by employer"
      comment.status = Comment::STATUS_NORMAL
      comment.save!
    end
  rescue Exception => e
    logger.error e
    render :nothing => true, status: :internal_server_error    
  end
end
