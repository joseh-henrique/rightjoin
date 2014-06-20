  #See https://docs.google.com/document/d/1-gzWQwPFz4frHKpTMInges9AqAyXpCsywKJj7pXfHgM/edit for documentation
require 'csv'
require 'uri'
require 'fileutils'
 
require_relative  'turk_utils'
     
INPUT = TurkUtils::INPUT
VAL = TurkUtils::VAL
VAL1 = TurkUtils::VAL1
VAL2 = TurkUtils::VAL2
VAL3 = TurkUtils::VAL3
TURKS_PER_HIT = TurkUtils::TURKS_PER_HIT

CHOSEN= TurkUtils::CHOSEN 

JOB_AD_URL=  TurkUtils::JOB_AD_URL
STATE = TurkUtils::STATE
NUM_REPEATS ="NumRepeats"  
ON = TurkUtils::ON 
OFF = TurkUtils::OFF 
ALL4EQ = "All4Eq_"# All three values equal in a boolean column (value from the search, and the  two answer values)

HIT_ID = TurkUtils::HIT_ID

BOARD_NAMES = TurkUtils::BOARD_NAMES
BOOLEAN_BASE_NAMES = TurkUtils::BOOLEAN_BASE_NAMES
WORKER_ID ="WorkerId"
REDO=TurkUtils::REDO

BOOL_NEW_HDR_PFXS = [INPUT, VAL1, VAL2, VAL3, CHOSEN, ALL4EQ]

TXT_BASE_NAMES = TurkUtils::TXT_BASE_NAMES  
TXT_NEW_HDR_PFXS = [VAL1, VAL2, VAL3, CHOSEN]

NEW_HEADERS_D=  [HIT_ID, "#{INPUT}#{TurkUtils::ORIG_AD_URL}", "#{INPUT}search"] +
            BOOLEAN_BASE_NAMES.map{|base_name|BOOL_NEW_HDR_PFXS.map{|pfx|pfx+base_name}}.flatten +
            TXT_BASE_NAMES.map{|base_name|TXT_NEW_HDR_PFXS.map{|pfx|pfx+base_name}}.flatten + [NUM_REPEATS]

MAX_LENS = {TurkUtils::TITLE=>50, TurkUtils::COMPANY=>50, TurkUtils::CITY=>25}
MIN_LENS = {TurkUtils::TITLE=>5, TurkUtils::COMPANY=> 5, TurkUtils::CITY=>5,  STATE=>2}
SHORTER_VALUE_PREFERRED = ["description",   TurkUtils::COMPANY, STATE, TurkUtils::CITY]
LONGER_VALUE_PREFERRED = [ "country_code",TurkUtils::TITLE, JOB_AD_URL ]
EMPTY_TEXTUAL_VALUE_ALLOWED =[STATE]


BLANK_VALS = TurkUtils::BLANK_VALS  

JOB_BOARDS = ["jobvite"]
ASSIGNMENT_STATUS = "AssignmentStatus"
$worker_tasks_by_id = Hash.new(0)
$worker_errors_by_id = Hash.new(0)
$worker_nil_vals_by_id = Hash.new(0)
$skipped_orig_urls =[] 


SERIOUS_SEV = 2
MEDIUM_SEV = 1
MILD_SEV = 0
LOGTHRESHOLD = 1

# The HIGHER severity is more likely to be printed
def logline(s,  severity = MILD_SEV, indent = 0)
 if  severity >= LOGTHRESHOLD 
   puts " " * indent + s
 end
end


def truncate(s)
  s[0...30]
end     

#increment  
BIG_ERROR=1
LITTLE_ERROR=0.5
WARNING_INCREMENT=0
def report_error(worker_id, hit_id, s, increment = BIG_ERROR)
     $worker_errors_by_id[worker_id] += increment
      log_s ="WorkerID #{worker_id}, HITId #{hit_id}. #{s} "
      unless increment==BIG_ERROR || increment ==WARNING_INCREMENT
        log_s += ", increment #{increment}"
      end
      if increment.zero?
        log_s  = "Warning: " +log_s 
      end
      sev = increment == BIG_ERROR ? MEDIUM_SEV : MILD_SEV
    logline log_s, sev
end        

def valid_job_ad_url?(url, hit_id, worker_id)
   #  If a URL is "N/A" we do treat it as VALID, because elsewhere  in the script, "N/A" is taken as a signal that the whole row is to be skipped.  
   if url.gsub("/","").upcase==TurkUtils::NOT_APPLICABLE 
     return true 
   end  
   
  begin
    URI.parse(url)
    #URL is OK, do nothing
  rescue
   
    unless url.start_with? "http"
       s= "Malformed job_ad_url \"#{url}\""
      report_error(worker_id, hit_id, s)

    else
       logline "WorkerID #{worker_id}, HITId #{hit_id}, ignoring malformed job_ad_url \"#{url}\" with HITId #{hit_id}", MILD_SEV
    end
    return false
  end
  
  if url.start_with?("http://www.indeed.com/rc") || url.include?("mturk.com/")
 
      s="Ignoring Indeed/MTurk URL which was given as job_ad_url: #{url} "
       report_error(worker_id, hit_id, s)
    return false
  end
  
  return true
end

def choose_mixed_case(vals)
    #If none are found with mixedcase, just choose the first val in the array
    vals.find(->{vals[0]}){|v| v.downcase!=v && v.upcase!=v}
end

#If there are 3 (or 2 or 1) values here, it will choose the most common one if possible.
# If there are mixed-case and single-cased values that are otherwise equal, it will choose mixed-case.
#
# If they are all different, it will return nil, allowing us to choose by length.
#
#If there are more than 3 values, it will correctly handle the case that all are equal
# or unequal. But it will get confused on the case where several are equal but not all. 
def choose_most_common_value(one_of_these)

#It is common to have less than 3 valid values, when some values are invalid.
 
 
  downcased = one_of_these.map{|s|s.downcase}
  uniq = downcased.uniq 
  if uniq.length == 1 #All same
    return choose_mixed_case(one_of_these) 
  elsif uniq.length == one_of_these.length
    return nil #All are different, will choose by length
  else
    raise "Cannot handle #{one_of_these.length} values"  if one_of_these.length!=TURKS_PER_HIT 
    if downcased[0]==downcased[1]
      return choose_mixed_case([one_of_these[0],one_of_these[1]])
    elsif downcased[0]==downcased[2]
      return choose_mixed_case([one_of_these[0],one_of_these[2]])
    elsif downcased[1]==downcased[2] 
      return choose_mixed_case([one_of_these[1],one_of_these[2]])
    end
  end
   
 
 
end

#In the case of relocation , val_input is always false -- the checkbox for the turks is always presented unchecked
def choose_and_set_boolean_vals(val1, val2, val3, val_input, base_hdr_name, existing_row)
    hit_id = TurkUtils.get_val(HIT_ID, existing_row, NEW_HEADERS_D )
    bools = [val1, val2, val3, val_input].map{|v|v==ON} 
    raise "invalid boolean for #{base_hdr_name} among #{[val1, val2, val3, val_input]}  for row  #{hit_id} " unless TurkUtils::valid_onOff_value(val1, val2, val3, val_input)
    
    true_count= bools.count{|v|v}
    if true_count > 2  # 3 or 4 out of 4 say 'true'
      chosen_val_bool = true
    elsif  true_count < 2  # 3 or 4 out of 4 say 'false'
       chosen_val_bool =  false
    else     # 2 out of 4 say 'true' and 2 say 'false'
       # Two turks disagreed with the original search value for #{base_hdr_name}. Let's trust the \"brave\" turks. HITID #{hit_id} 
        val_input_bool = bools[-1]
        chosen_val_bool = val_input_bool
    end 

    chosen_val = chosen_val_bool ? ON : OFF
   
    TurkUtils.set_val(chosen_val, "#{CHOSEN}#{base_hdr_name}", existing_row, NEW_HEADERS_D)
   
    all_4_eq_bool = (bools.count === bools.select{|v|v==bools[0]}.count) 
    all_4_eq = all_4_eq_bool ? "eq": "NEQ"
 
    TurkUtils.set_val(all_4_eq, "#{ALL4EQ}#{base_hdr_name}", existing_row, NEW_HEADERS_D)
    
    
end 
               


#return true if should skip this row
def choose_and_set_textual_vals(val1, val2, val3, base_hdr_name, existing_row)
     hit_id = TurkUtils.get_val( HIT_ID, existing_row, NEW_HEADERS_D )
     choose_from = [val1, val2, val3]
   
    if indeed_url_declared_not_applicable(base_hdr_name, choose_from, hit_id,existing_row)
      return true
    end
  
     choose_from = choose_from.map{|val| val.strip}
     # Note that delete_if() mutates array
    
     choose_from.delete_if{|val| BLANK_VALS.include?(val.downcase)  } 
        
     chosen_val = choose_most_common_value(choose_from) #  
     
     #The following code accounts for the case where values are all equal. ALso, when there are two different vals of same length, it chooses one. 
     if chosen_val.nil?
         if choose_from.empty?
            chosen_val = ""
         else 
            if SHORTER_VALUE_PREFERRED.include?(base_hdr_name) 
              chosen_val = choose_from.min { |a, b| a.length <=> b.length }
              #Does not account for the case where the two minlengths strings have differing case 
            elsif LONGER_VALUE_PREFERRED.include?(base_hdr_name)  
              chosen_val = choose_from.max { |a, b| a.length <=> b.length } 
            else
              raise "unknown header #{base_hdr}"
            end
         end
     end

     if chosen_val.nil? || chosen_val.empty? && !EMPTY_TEXTUAL_VALUE_ALLOWED.include?(base_hdr_name)
        logline "skipping row with all-invalid #{base_hdr_name} values [#{val1}, #{val2}, #{val2}], HITID #{hit_id}", MEDIUM_SEV
        return true 
     else
       
      chosen_val_downcase =chosen_val.downcase
      if ( /\bintern\b/.match(chosen_val_downcase) || /\bco-op\b/.match(chosen_val_downcase)) && base_hdr_name == TurkUtils::TITLE
           logline "Skipping #{hit_id} because \"#{chosen_val}\" is an intern/Co-op job.", MILD_SEV
           return true 
      end
 
     TurkUtils.set_val( chosen_val, "#{CHOSEN}#{base_hdr_name}", existing_row, NEW_HEADERS_D)
     
     #Blank out redundant vals (those which are the same as chosen vals) 
     [VAL1, VAL2, VAL3].each {|pfx|     
          val = TurkUtils.get_val( "#{pfx}#{base_hdr_name}",  existing_row, NEW_HEADERS_D)
          val = "" if BLANK_VALS.include?(val.strip.downcase)
     
          if  val.downcase==chosen_val.downcase
            val = "" 
          end
         
         if val.empty? 
              TurkUtils.set_val("", "#{pfx}#{base_hdr_name}",  existing_row, NEW_HEADERS_D)
          end
      }
    
     return false #No need to skip  
   end
end



def indeed_url_declared_not_applicable(base_hdr_name, choose_from, hit_id,row)
  if base_hdr_name==JOB_AD_URL
      job_not_applicable = choose_from.find{|v|v.gsub("/","").upcase==TurkUtils::NOT_APPLICABLE} 
      if job_not_applicable
         logline "Skipping row since a turk declared it N/A, HITID #{hit_id}", MEDIUM_SEV 
         return true
      end 
  end
  return false
end

def set_chosen_values(row)
      skip_row = false
      
      NEW_HEADERS_D.each do |hdr_name|
        if hdr_name.start_with? VAL1
           base_hdr_name = hdr_name[VAL1.length..-1]
           val1, val2, val3 = (1..TURKS_PER_HIT).map{|i|TurkUtils.get_val("#{VAL}#{i}#{base_hdr_name}", row, NEW_HEADERS_D)}
 
     
           if BOOLEAN_BASE_NAMES.include? base_hdr_name
               input_vals_provided = BOARD_NAMES.include?(base_hdr_name)
               val_input = TurkUtils.get_val("#{INPUT}#{base_hdr_name}", row, NEW_HEADERS_D, input_vals_provided)
               choose_and_set_boolean_vals(val1, val2, val3, val_input, base_hdr_name, row)
           end
            
            if TXT_BASE_NAMES.include? base_hdr_name
               skip_row  ||= choose_and_set_textual_vals(val1, val2, val3, base_hdr_name, row)
            end
          end
      end
      
      if skip_row
        $rows_skipped+=1
        row.clear
      end 
end   


def empty_vals(row)
  blanks = row.select{|v|v.nil? || v.empty?}
  return blanks.length==row.length
end

def merge_multiple_answers(input_row, arr_of_arr_output, hdr_from_file)
   return if empty_vals(input_row)
   hit_id =  TurkUtils.get_val( HIT_ID ,input_row, hdr_from_file )
   orig_ad_url= TurkUtils.get_val( INPUT+ TurkUtils::ORIG_AD_URL ,input_row, hdr_from_file )

  
    #TODO Extract the following "earlier  row with this Indeed URL" logic
    earlier_row_for_this_ad=get_row_from_arr_of_arr(INPUT+ TurkUtils::ORIG_AD_URL, orig_ad_url, arr_of_arr_output)
    if earlier_row_for_this_ad
      earlier_hit_id =  TurkUtils.get_val( HIT_ID ,earlier_row_for_this_ad, NEW_HEADERS_D )
      if hit_id!=earlier_hit_id
        TurkUtils.set_val(earlier_hit_id, HIT_ID, input_row,hdr_from_file)
          hit_id=  earlier_hit_id
      end
    end
    
    worker_id = TurkUtils.get_val(WORKER_ID, input_row, hdr_from_file )
    $worker_tasks_by_id[worker_id]+=1

    raise "No HITId in #{input_row} " if hit_id.nil? || hit_id.empty?
    
    reject_or_approved = TurkUtils.get_val( ASSIGNMENT_STATUS ,input_row, hdr_from_file )
    if  reject_or_approved =="Rejected"
      
        s= "skipping Rejected row"
        report_error(worker_id, hit_id, s)
         $rows_skipped+=1
      return
    end
    
    
    new_row = make_new_row(hit_id, arr_of_arr_output)
    num_repeats  = calc_and_set_num_repeats(new_row)
    
    hdr_from_file.each do |hdr_name|
        set_val_for_hdr(hdr_name, input_row, hdr_from_file,new_row,num_repeats)
    end
         
   if num_repeats==TURKS_PER_HIT
      set_chosen_values(new_row)
   end
end

def make_new_row(hit_id, arr_of_arr_output)
    new_row = TurkUtils.get_row_from_arr_of_arr(HIT_ID , hit_id, arr_of_arr_output)
    
    if new_row.nil?  
        new_row = [].fill(0, NEW_HEADERS_D.length)
        arr_of_arr_output << new_row
    end 
   return new_row
end

def calc_and_set_num_repeats(new_row)
    old_num_repeats_s  = TurkUtils.get_val(NUM_REPEATS, new_row, NEW_HEADERS_D)
    old_num_repeats_s = "0" if old_num_repeats_s.empty?
    old_num_repeats = old_num_repeats_s.to_i
    num_repeats = old_num_repeats + 1
    TurkUtils.set_val(num_repeats.to_s, NUM_REPEATS, new_row, NEW_HEADERS_D)
    return num_repeats
end


def set_val_for_hdr(hdr_name,  input_row, hdr_from_file, new_row,num_repeats)
   
  base_hdr_name = get_base_hdr_name(hdr_name)
     
  hit_id =  TurkUtils.get_val( HIT_ID ,input_row, hdr_from_file, num_repeats)
  worker_id = TurkUtils.get_val(WORKER_ID, input_row, hdr_from_file )
  input_base_names = BOARD_NAMES + [TurkUtils::SEARCH, TurkUtils::ORIG_AD_URL]
  
 
  if hdr_name==HIT_ID || hdr_name.start_with?(TurkUtils::ANSWER) || (hdr_name.start_with?(INPUT) && input_base_names.include?(base_hdr_name) ) 
     val = TurkUtils.get_val(hdr_name, input_row, hdr_from_file )
      if !val.empty? && BLANK_VALS.include?(val.downcase)
           $worker_nil_vals_by_id[worker_id]+=1
            
      end 
 
 
     new_hdr_name = get_new_hdr_name(base_hdr_name, hdr_name, num_repeats,hit_id)
     
     val = ignore_invalid_url_or_add_http_pfx(base_hdr_name, val,hit_id, worker_id)
     val = ignore_overlong_answer(base_hdr_name, val,  hit_id, worker_id)
 
     val = clean_comma(base_hdr_name, val)
     val = clean_washington(base_hdr_name, val)
     val = clean_incorporated_tag(base_hdr_name, val, hit_id)
 
     val = clean_us_as_state_name(base_hdr_name, val, hit_id, worker_id)
     val = clean_can_as_state_name(base_hdr_name, val, hit_id, worker_id) 
     val = clean_req_num_in_title(base_hdr_name, val,hit_id)
     val = clean_level_num_in_title(base_hdr_name, val,hit_id)
    val = clean_senior_and_junior(base_hdr_name, val,hit_id)
     
     TurkUtils.set_val(val, new_hdr_name, new_row, NEW_HEADERS_D)
  end 
end

def get_base_hdr_name(hdr_name)
  idx = hdr_name.index(".")
  if idx
    base_hdr_name = hdr_name[idx+1..-1].strip
  else 
    base_hdr_name = hdr_name
  end
end


def get_new_hdr_name(base_hdr_name, hdr_name, num_repeats, hit_id)
   if hdr_name.start_with?(TurkUtils::ANSWER)
        raise "Too many repeats for #{hit_id}" if num_repeats > TurkUtils::TURKS_PER_HIT
        pfx = "#{VAL}#{num_repeats}"
        new_hdr_name ="#{pfx}#{base_hdr_name}"
        return new_hdr_name 
      elsif hdr_name.start_with?(INPUT) || hdr_name==HIT_ID
        new_hdr_name = hdr_name
        return new_hdr_name 
      end
      raise "unexpected " + hdr_name
end

def ignore_invalid_url_or_add_http_pfx(base_hdr_name, val, hit_id, worker_id)
   if base_hdr_name == JOB_AD_URL
       val = "http://"+val  if val.start_with? "www."
       val = "" unless valid_job_ad_url?(val, hit_id, worker_id) # This method prints warning msg if needed.
   end
   return val
end

def warn_on_short_answer(base_hdr_name, val, hit_id, worker_id)
    min_len = MIN_LENS[base_hdr_name]
    if min_len
     if val.length < max_len  
        report_error worker_id, hit_id, "Too-short #{base_hdr_name} of length #{val.length}, min #{max_len}, value is \"#{val[0..max_len]}...\" "
      end
    end
    return val
end

def ignore_overlong_answer(base_hdr_name, val, hit_id, worker_id)
    max_len = MAX_LENS[base_hdr_name]
    if max_len
     if val.length > max_len# Shorter value preferred for city and country; though not for title; so for city and country, this is not strictly needed, since too-long vals will be ignored anyway 
        if val.length >= max_len * 2# Only count extreme variations as error; otherwise warning
            
            s= ". Ignoring overlong #{base_hdr_name} of length #{val.length}, max #{max_len}, value is \"#{val[0..max_len]}...\" "
            report_error(worker_id, hit_id,s)
            val = ""
        else
           report_error worker_id, hit_id, "#{base_hdr_name} of length #{val.length}, max #{max_len}, value is \"#{val[0..max_len]}...\" " , WARNING_INCREMENT
        end
        

      end
    end
    return val
end

 def clean_senior_and_junior(base_hdr_name, val,hit_id)
   old_val=val
  if base_hdr_name==TurkUtils::TITLE
 
      val = val.gsub(/(\bSr[\.?\b])/i, "Senior") 
      val = val.gsub(/(\bJr[\.?\b])/i, "Junior")
      if old_val !=val
        logline "Replaced \"#{old_val}\" with \"#{val}\", HIT Id #{hit_id}"
      end
   end 
 return val
end

#Remove comma on forms like "Austin,"
def clean_comma(base_hdr_name, val)
  val = val[0...-1]  if [TurkUtils::CITY, TurkUtils::STATE, TurkUtils::COMPANY].include?(base_hdr_name) &&  val[-1]=="," 
  return val
end

def clean_washington(base_hdr_name, val)
  val = "Washington"  if base_hdr_name==TurkUtils::CITY  &&  "washingtondc" == val.downcase.gsub(".","").gsub(" ","").gsub(",","")
 return val
end

def clean_incorporated_tag(base_hdr_name, val, hit_id)
 
  if base_hdr_name==TurkUtils::COMPANY
    base_regex =  'CORPINDICATOR\.?\s*$'
 
    corp_indicators = ["inc", "ltd","llc", "corporation", "corp"]
    regexes1= corp_indicators.map{|corp_indicator|  base_regex.gsub("CORPINDICATOR",corp_indicator)}
    regexes_with_comma = regexes1.map{|r|',\s*'+r}
    regexes = regexes_with_comma + regexes1 # First the fuller versions with comma to make sure they are checked first
    val_new =val
    regexes.each{|r|
      regex =Regexp.new(r, Regexp::IGNORECASE)
      val_new =val.gsub(regex,"").strip
      
      break if val!=val_new
    }
    if val!=val_new
          logline "Replaced \"#{ val}\" with \"#{ val_new}\", HITID #{hit_id}"
    end
    val = val_new
  end
 return val
end

def clean_req_num_in_title(base_hdr_name, val, hit_id)
   if base_hdr_name ==TurkUtils::TITLE
        val_new = val.gsub(/\s*[(#-]?\s*\d\d+\)?\s*/, "")
       if  val_new != val
           logline "title with apparent req number, changing from \"#{ val}\" to \"#{ val_new}\", HITID #{hit_id}"
           val =  val_new
       end
   end
   return val
end

#  Replace Software Engineer II or III by Senior Software Engineer; Replace Software Engineer I by  Software Engineer. 
# Will not match Software Engineer IV. 
# Will not match  Software Engineer III Test (i.e., roman numeral must be at end of string)
def clean_level_num_in_title(base_hdr_name, val, hit_id)

     ret = val
     if base_hdr_name ==TurkUtils::TITLE
        match = /^(.*)\s+(i{1,3})$/i.match(val.strip)
       
        if match 
           number = match[2].downcase
           if number =="i" 
             ret =  match[1]
           else
             ret = "Senior #{match[1]}"
           end
        end  
    end  

    if  ret != val
       logline "Changing roman-numeral title from \"#{ val}\" to \"#{ ret}\", HITID #{hit_id}", MILD_SEV
    end
     
    return ret
end

def clean_us_as_state_name(base_hdr_name, val, hit_id, worker_id)
   if base_hdr_name==STATE && val.upcase==TurkUtils::US.upcase
      s = "Ignoring state \"#{val}\""      
      report_error(worker_id, hit_id, s, LITTLE_ERROR)
    val = ""  
   end
   return  val
end

def clean_can_as_state_name(base_hdr_name, val, hit_id, worker_id)
   if base_hdr_name==STATE && val.upcase.start_with?("CAN") 
      s= "Worker ID #{worker_id}, HitId #{hit_id}, ignoring state \"#{val}\""
      report_error(worker_id, hit_id, s)
    val = ""  
   end
   return  val
end

def print_worker_problems
    logline "\n#{$worker_tasks_by_id.size} workers;  #{$worker_tasks_by_id.values.inject{|sum,x| sum + x }} turk-tasks were done (#{TURKS_PER_HIT} per HIT)", SERIOUS_SEV
    workers_with_no_errors = $worker_tasks_by_id.keys - $worker_errors_by_id.keys
    workers_with_no_errors.each{|id|$worker_errors_by_id[id]=0  }
  num_problems =$worker_errors_by_id.values().inject(0, :+)
    logline("There were #{num_problems} errors", SERIOUS_SEV)
    problems = $worker_errors_by_id.to_a
     #Sort by fraction of problems in their work
    problems.sort_by!{|worker_and_problem_count | 
                        -(worker_and_problem_count[1].to_f / $worker_tasks_by_id[worker_and_problem_count[0]]) }
   
  
     problems.each do |worker_and_problem_count|
        worker_id=worker_and_problem_count[0]
        err_count=worker_and_problem_count[1]
        task_count=$worker_tasks_by_id[worker_id]
        logline "#{worker_id}:\t#{err_count} errors out of #{task_count} tasks (#{(100*(err_count.to_f / task_count.to_f)).round}%)" , SERIOUS_SEV
     end
     
     logline "\n\nNil values (such as \"N/A\" or \"None\")", SERIOUS_SEV
     
     nils = $worker_nil_vals_by_id.to_a
     nils.sort_by!{|worker_and_nil_count | 
                        -(worker_and_nil_count[1].to_f / $worker_tasks_by_id[worker_and_nil_count[0]]) }
   
     nils.each{|worker_and_nil_count|
        worker_id = worker_and_nil_count[0]
        nil_count = worker_and_nil_count[1]
       task_count=$worker_tasks_by_id[worker_id]
        logline "#{worker_id} has #{nil_count} nil vals out of #{task_count} tasks (ratio #{(  nil_count.to_f / task_count.to_f).round(2)  })", SERIOUS_SEV
     }
end
 
 
 
def prepare_redo_for_partially_completed(rpts_hash)
  logline "\nCompleteness report: Number of URLs done this many times" , SERIOUS_SEV
  vals = rpts_hash.values
 ignore_rows_done_zero_times=false
  (TURKS_PER_HIT+1).times{|n|#0,1,2,3
      count =vals.count(n)
      logline " #{n} times: #{count} URLS" , SERIOUS_SEV, 1
           
       if n==0 # i.e., items not done at all
         if count > 0 && count  > $rows_skipped
           logline "Some rows were left undone by turks ",SERIOUS_SEV, 3
         elsif $rows_skipped >0
           logline "The #{$rows_skipped} skipped rows were dropped by this script. They were not left undone by the turks.", SERIOUS_SEV, 3
           ignore_rows_done_zero_times= true
         end
       end
  }
  
  Dir.mkdir(REDO) unless Dir.exist?(REDO)
  File.open("#{REDO}/#{REDO}.txt", 'w') { |f| 
   rpts_hash.each{|k,v|
     if v.to_i ==0 && ignore_rows_done_zero_times
        #
     else
        (TURKS_PER_HIT-v).times{
           f.write(k +"\n") 
        }
     end
      }
  }
end

def find_missing_urls(rpts_hash)
   original_url_list = "#{TurkUtils::URL_LIST}/#{TurkUtils::EDITED_URL_LIST}.csv"
   arr_of_arr_from_file  = CSV.read(original_url_list)
   hdr_from_file = arr_of_arr_from_file.shift
   arr_of_arr_from_file.each{|row| 
        orig_ad_url_= TurkUtils.get_val( TurkUtils::ORIG_AD_URL,row, hdr_from_file )
        
        rpts_ = rpts_hash[orig_ad_url_]
        unless rpts_
           rpts_hash [orig_ad_url_] = 0
         end
     }
  
      
 end

def calculate_missed_repeats(arr_of_arr_output)
  rpts_hash={}
  arr_of_arr_output[1..-1].each{|output_row|
      rpts  = TurkUtils.get_val( NUM_REPEATS,output_row, NEW_HEADERS_D)
      orig_ad_url = TurkUtils.get_val( "#{INPUT}#{TurkUtils::ORIG_AD_URL}",output_row, NEW_HEADERS_D)
      if rpts.to_i != TURKS_PER_HIT 
          logline "URL #{orig_ad_url} has #{rpts} repeats", MILD_SEV
      end 
     
      rpts_hash[orig_ad_url]=  rpts.to_i
   }
   find_missing_urls(rpts_hash)
   
   prepare_redo_for_partially_completed(rpts_hash)   
end
   
OUTPUT_DIR_NAME = "merged_turk_work"
TURK_JOB_ADS = "turk_job_ads"

def main
  $rows_skipped=0 
  file  = File.new("#{TURK_JOB_ADS}/#{TURK_JOB_ADS}.csv")
  arr_of_arr_output = TurkUtils.read_file(file,NEW_HEADERS_D, :merge_multiple_answers)
    
   calculate_missed_repeats(arr_of_arr_output)
   
  Dir.mkdir(OUTPUT_DIR_NAME) unless Dir.exist?(OUTPUT_DIR_NAME)
  TurkUtils.write_file("#{OUTPUT_DIR_NAME}/#{OUTPUT_DIR_NAME}.csv", arr_of_arr_output)

  logline "#{ arr_of_arr_output.count} output lines"
  logline "#{$rows_skipped} rows skipped."
  print_worker_problems
end



main()
