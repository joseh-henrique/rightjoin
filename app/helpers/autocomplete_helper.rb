module AutocompleteHelper
  def suggest(model, count)
    model.all(:select => 'id, name as label', :conditions => ["priority > 0 and name ILIKE ?", params[:term] + "%"],:order => ["priority DESC, name ASC"],:limit => count)
  end
  
  def suggest_commonly_used(model, count)
    model.all(:select => 'id, name as label', :conditions => ["priority > 0"],:order => ["priority DESC, name ASC"],:limit => count)
  end    
end
