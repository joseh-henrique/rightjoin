module WidgetsHelper
  AMBASSADOR_LIMIT = 50
  def get_summary_tuples
    block = Proc.new{
      num_visible_items = 4
      interview_limit = 12
      user_limit = 48
  
      usrs = User.where("status = ? and (sample is null or sample = false)", UserConstants::VERIFIED).order("id DESC").limit(user_limit)
      intervws = Interview.unscoped.joins(:employer).where("employers.sample is null or employers.sample = false").order("id DESC").limit(interview_limit)
        
       # assertion-style check follows
      if Rails.env.development?
        raise "Sample found " unless usrs.find_all{|u|u.sample}.empty?
        raise "Too many " unless usrs.count <= user_limit
        raise "Wrong order" unless usrs.sort_by{|u| -u.id } ==usrs
        raise "Sample found " unless intervws.find_all{|i|i.employer.sample}.empty?   
        raise "Too many " unless intervws.count <= interview_limit
        raise "Wrong order" unless intervws.sort_by{|i| -i.id } ==intervws
      end
      
      usrs, intervws = add_samples_if_needed(usrs, intervws, num_visible_items)
  
      array = usrs + intervws
      array.shuffle!
      
      mod = (array.length) % num_visible_items
      array = array[0...(-mod)] unless mod==0 # round off to modulo 4
      
      array_of_quadruples = array.each_slice(num_visible_items).to_a
      array_of_quadruples
    }
     
    if Rails.env.development? # Rails.cache not working in dev because it is not finding class Interview
      tuples= block.call()
    else
      tuples = Rails.cache.fetch("summary_sample", :expires_in => 3.days) do
        block.call()
      end
    end
    return tuples
   end  
  
private
  # The cycling of the summaries does not work with less than two whole rotation units. 
  # This is a problem in development, where most users in the system  are samples. 
  # So, we make sure to take enough users, using samples if needed.
  def add_samples_if_needed(usrs, intervws, num_visible_items)
    if Rails.env.development?
        missing_usrs_needed = num_visible_items - usrs.length  
        if missing_usrs_needed > 0 
          sample_usrs = User.where("status = ? and (sample is true)", UserConstants::VERIFIED).order("id  DESC").limit(missing_usrs_needed)
          usrs += sample_usrs
        end
        
        missing_interviews_needed = num_visible_items - intervws.length  
        if missing_interviews_needed > 0
          sample_intervws = Interview.unscoped.joins(:employer).where("employers.sample = true").order("id DESC").limit(missing_interviews_needed)
          intervws += sample_intervws 
        end
    end
    
    return usrs, intervws
  end
   
  
  # Create a one-line summary of a User or Interview. 
  # Note that max_line_length will include the final elipsis if needed. 
  # param o can be a user or an interview
  # param max_line_length will _include_ final elipsis if needed. 
  def summary_line(o, max_line_length)
    line = ""
    
    case o  
    when User
      line = summary_line_for_user(o, max_line_length)

    when Interview
      line = summary_line_for_interview(o, max_line_length)
    else
      raise "Unknown type: #{o}"
    end
      
    return line
  end
  
  def summary_line_for_user(usr, max_line_length)
    txt_tag_pairs = [];
    txt_tag_pairs << [usr.current_position_name,"current-position"]
    txt_tag_pairs += tail_of_user_summary_line(usr) 
  
    line = Utils.truncate_html(txt_tag_pairs, max_line_length, true) 
    return line
  end  
  
  def tail_of_user_summary_line(usr)
     retval = ""
     
     def self.join_with_commas(pairs)
         pairs_with_comma=[]
         pairs.each do|pair|
            pairs_with_comma << pair
            pairs_with_comma << [", ",nil]
        end
        pairs_with_comma = pairs_with_comma[0, pairs_with_comma.length-1]
     end
     
     
     if usr.wanted_position.id == usr.current_position.id
        retval = [[" seeking a better ", nil]]
     else
        retval = [[" seeking ", nil], [usr.wanted_position_name, "wanted-position"]]
     end
    
     req_names = usr.user_job_qualifiers.map{ |q| q.job_qualifier_tag.name}
     req_pairs = req_names.zip(["req"] * req_names.length) # sets "req as the class for all the requirement tags 
  
     if usr.wanted_salary > 0
         sal_pair=["#{Utils::format_currency(usr.wanted_salary/1000, usr.locale)}K+","salary"]
         # Insert salary, not at beginning (salary should not be top priority) and not at the end (where it can get truncated)
         position_for_salary = [2, req_pairs.length].min # account for the case where there are 0 or 1 requirements 
         req_pairs.insert(position_for_salary, sal_pair)
     end
   
     if req_pairs.empty?
        retval << [" job",nil]
     else
        reqs_with_commas = join_with_commas(req_pairs)
        retval << [" job with ",nil]  
        retval += reqs_with_commas       
     end

     retval
   end
  
  
  def summary_line_for_interview(interview, max_line_length)
    usr = interview.user
    retval = [[" contacted by ",nil], [interview.job.company_name,"company-name"]]
    
    txt_tag_pairs = [];
   
    txt_tag_pairs << [usr.current_position_name, "current-position"]
    txt_tag_pairs += retval unless retval.nil?
    
    line = Utils.truncate_html(txt_tag_pairs, max_line_length, true)  
    return line
  end  
  
end