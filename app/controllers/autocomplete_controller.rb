class AutocompleteController < ApplicationController
  include AutocompleteHelper
 
## commenting out caching. should not be really needed now  
#  caches_action :locations, :expires_in=>5.days, :cache_path => Proc.new { |c| c.params }
#  caches_action :skills, :expires_in=>5.days, :cache_path => Proc.new { |c| c.params }
#  caches_action :positions, :expires_in=>5.days, :cache_path => Proc.new { |c| c.params }
#  caches_action :jobqualifiers, :expires_in=>5.days, :cache_path => Proc.new { |c| c.params }
  
  def skills
    term = params[:term]
    num = params[:num].to_i
    for_role = params[:extra]
    extra ||= ""
    term = "" unless  term   
    if term.length < 2 # term is too short, try to return best suggestions for the given role
      popular_tags = SkillTag.popular_for_role(for_role, num)
      popular_tags = SkillTag.popular_for_role("", num) if  popular_tags.size == 0 # fallback to most popular for all
      
      suggests = popular_tags.collect do |tag| 
        {:label => tag.name, :id => tag.id}
      end
      
      suggests = suggest(SkillTag, num) if suggests.size == 0 # fallback to default prioritites in DB
    else
      suggests = SkillTag.autocomplete.suggest(term, num) # term is long enough, suggest using trie ignoring target role
    end
    
    respond_to do |format|
      format.js { render :json => suggests }
    end
  end
  
  def positions
    term = params[:term]
    num = params[:num].to_i
    for_role = params[:extra]
    term ||= ""
    extra ||= ""
    
    if term.length < 2 # term is too short, try to return best suggestions for the given role
      popular_tags = PositionTag.popular_for_role(for_role, num)
      popular_tags_for_all = PositionTag.popular_for_role("", num) if  popular_tags.size < num # fallback to most popular for all
      
      popular_tags ||= []
      popular_tags_for_all ||= []
            
      suggests = []
      suggests = [{:label => for_role, :id => -1}] unless for_role.blank? # id left -1 as it's not currently in use, but be careful, it's a time bomb
      
      popular_tags = (popular_tags + popular_tags_for_all).uniq.first(num - suggests.size)
      
      suggests += popular_tags.select{|v| v.name.downcase != for_role.downcase}.collect do |tag| 
        {:label => tag.name, :id => tag.id}
      end
      
      suggests = suggest(PositionTag, num) if suggests.size == 0 # fallback to default prioritites in DB
    else
      suggests = PositionTag.autocomplete.suggest(term, num) # term is long enough, suggest using trie ignoring target role
    end
        
    respond_to do |format|
      format.js { render :json => suggests }
    end
  end
  
  def jobqualifiers
    respond_to do |format|
      format.js { render :json => JobQualifierTag.autocomplete.suggest(params[:term], params[:num].to_i) }
    end
  end
  
  def locations
    respond_to do |format|
      format.js { render :json => LocationTag.autocomplete.suggest(params[:term], params[:num].to_i) }
    end
  end  
  
  @@benefits_autocomplete = nil
  def benefits
    if @@benefits_autocomplete.nil?
      @@benefits_autocomplete = Autocomplete.new(Constants::BENEFITS)
    end
    
    respond_to do |format|
      format.js { render :json => @@benefits_autocomplete.suggest(params[:term], params[:num].to_i) }
    end    
  end
  
private
#  def render_autocomplete(model)
#    respond_to do |format|
#      format.js { render :json => suggest(model, 8) }
#    end
#  end
end
