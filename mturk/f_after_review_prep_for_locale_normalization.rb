#See https://docs.google.com/document/d/1-gzWQwPFz4frHKpTMInges9AqAyXpCsywKJj7pXfHgM/edit for documentation
require 'csv'
require 'pp'
require_relative  'turk_utils'

def dash_to_uscore(s)
  return s.gsub("_","-")
end
$board_count= Hash.new(0)

LC_REMOTE_WORK_DESIGNATORS = [ "telecommuting", "remote", "", TurkUtils::TELECOMMUTE.downcase]

SHORTER_VALUE_PREFERRED = ["description",  TurkUtils::COMPANY, TurkUtils::STATE, TurkUtils::CITY ]
LONGER_VALUE_PREFERRED = [ "country_code",TurkUtils::TITLE ]
INDEED_PARAM_PAIRS = [  
                        "utm_182um=Indeed",
                        "utm_campaign=XMLFeed", 
                        "eresc=Indeed", 
                        "utm_campaign=jwt_ppc_indeed_IT_ef", 
                        "utm_campaign=Indeed",
                        "utm_medium=Indeed",
                        "utm_source=Indeed",
                        "from=indeed",
                        "src=indeed",
                        "siteid=cbindeed",
                        "Board=Indeed",
                        "iisn=Indeed.com",
                        "iisn=Indeed",
                        "jvs=Indeed",
                        "referer=indeed",
                        "source=indeed.com",
                        "source=Indeed",
                        "WT.mc_n=Indeed_US",
                        "iis=Job+Board-+Indeed.com", 
                        "iis=Indeed",
                        "s=Indeed",
                        "siteid=indeedorgsg",
                        "iis=Job+Board+-+Indeed",
                        "jobpipeline=Indeed",
                        "referrer=www.indeed.com", 
                         "src=Online/Job%20Board/indeed"  ,
                         "apstr=%2526codes%253DIndeed",
                         "zmc=Indeed",
                         "&ad=indeed",
                         "cc_indeed" ,
                         "source=feed-indeed",
                         "jtsrc=www%2Eindeed%2Ecom",
                         "sourceVariation=Indeed",
                         "source=Internet:++Indeed",
                         "codes=I-Indeed",
                         "sourcename=Indeed",
                         "ref=indeed.com",
                         "name=Indeed",
                         "source=POSTING-INDEED",
                         "ref=indeed",
                         "codes=IN-JBIndeed",
                         "siteid=indeedorgcr",
                         "ad=recruiticsindeed",
                         "rf=INDEED",
                         "WT.mc_n=Indeed_CA",
                          "source=Internet+-+Indeed",
                          "utm_campaign=Citrix_Indeed",
                          "codes=1-INDEED",
                          "%26iisn%3DIndeed" ,
                          "WT.mc_id=ADW_NJOBS_1305_INDEEDORG",
                          "iis=Internet+-+Indeed"  ,
                          "utm_campaign=TASC_Indeed",
                          "cid=IndeedOrganic",
                          "utm_campaign=Postings_Indeed",
                          "codes=IINDEED"
                        ]
                        
INDEED_PARAM_PAIRS_REGEXES =[/rx_campaign=Indeed\d+/ ]

INPUT=TurkUtils::INPUT

COPY_THESE_VALS = [TurkUtils::HIT_ID, "#{INPUT}orig_ad_url","#{INPUT}search"]

JOB_AD_URL =  TurkUtils::JOB_AD_URL
CHOSEN = TurkUtils::CHOSEN
TXT_BASE_NAMES_EXCEPT_JOB_AD_URL = TurkUtils::TXT_BASE_NAMES.reject{|base_name| base_name==JOB_AD_URL}
NEW_HEADERS_F = (COPY_THESE_VALS + [JOB_AD_URL] +
                        TurkUtils::BOOLEAN_BASE_NAMES +
                        TXT_BASE_NAMES_EXCEPT_JOB_AD_URL).map{|bn| dash_to_uscore(bn)}

# idx is index of the problematic "indeed"-string 
def process_url(dirty_url, idx, match_len)
    if idx
          amp_before = dirty_url[idx-1]=="&"
          amp_after = dirty_url[idx+match_len]=="&"
          if amp_after # also handles case where we have both amp_after and amp_before
            ret = dirty_url[0..idx-1] + dirty_url[idx+match_len+1..dirty_url.length]
          elsif amp_before # but not amp_after
            ret = dirty_url[0..idx-2]+ dirty_url[idx+match_len..dirty_url.length]
          else # No ampersand: Handles http://cnn.com?s=Indeed
            ret = dirty_url[0..idx-1]+ dirty_url[idx+match_len..dirty_url.length]
          end
        if ret.nil? || ret.empty?# We get a valid, though dirty, URL, so the return value must be non-empty
           raise "bad return val"
         end
     else
       ret = dirty_url 
     end
     return ret
     
end  

def clean_indeed_references(dirty_url)
  # if s& and no & before, delete s&
  # if &s& delete s&
  # if &s and no & afterwards, delete &s
  INDEED_PARAM_PAIRS_REGEXES.each {|param_pair_regex|
      idx = dirty_url.index(param_pair_regex)
      if idx
        match_len = dirty_url.match(param_pair_regex)[0].length
      end
      dirty_url = process_url(dirty_url, idx,match_len)
  }
 
  2.times do #Twice because the there can be two param-pairs, including repetitions. However, this won't handle the case where they are repeated 3 times 
    INDEED_PARAM_PAIRS.each {|param_pair|
        idx = dirty_url.downcase.index(param_pair.downcase)
        dirty_url=process_url(dirty_url, idx,param_pair.length)
    }
  end
      
  return dirty_url        
end
 
def test_clean()
   # Verify that INDEED_PARAM_PAIRS are ordered correctly. 
   # For example, we cannot allow source=indeed to be scanned and replaced before source=indeed.com
    (0...INDEED_PARAM_PAIRS.length).each {|idx|
      (0...idx).each{|earlier_idx| #O(n^2), but that's not a big deal.
        if INDEED_PARAM_PAIRS[idx].downcase.include?(INDEED_PARAM_PAIRS[earlier_idx].downcase)
          raise "#{INDEED_PARAM_PAIRS[idx]} includes #{INDEED_PARAM_PAIRS[earlier_idx]}"  
        end
        }
    }     
  #should do the same for regexes but it is impossible to determine if one regex "includes" another (i.e., the set of strings it matches is a subset of the set of strings that the other matches)
  
  test_expected_io = 
  { 
      "http://cnn.com?a=b&rx_campaign=Indeed15&d=e"=>"http://cnn.com?a=b&d=e",
      "http://cnn.com?a=b&rx_campaign=Indeed5&d=e"=>"http://cnn.com?a=b&d=e",
      "http://cnn.com?a=b&rx_campaign=Indeed144&d=e"=>"http://cnn.com?a=b&d=e",
      "http://cnn.com?a=b&rx_campaign=Indeed&d=e"=>"http://cnn.com?a=b&rx_campaign=Indeed&d=e",
      "http://www.dice.com/job/result/RTL183292/387452?c=1&src=20&utm_source=Indeed&utm_medium=Aggregator&utm_content=&utm_campaign=Advocacy_Ongoing&rx_source=Indeed&rx_campaign=Indeed0&CMPID=AG_IN_UP_JS_AV_OG_RC_"=>"http://www.dice.com/job/result/RTL183292/387452?c=1&src=20&utm_medium=Aggregator&utm_content=&utm_campaign=Advocacy_Ongoing&rx_CMPID=AG_IN_UP_JS_AV_OG_RC_",
      "http://www.startuphire.com/job/software-developer-javascript-gui-lynnwood-wa-wideorbit-236716?utm_source=Indeed&utm_medium=organic" => "http://www.startuphire.com/job/software-developer-javascript-gui-lynnwood-wa-wideorbit-236716?utm_medium=organic", 
      "http://a.com?siteid=cbindeed&x"  => "http://a.com?x",
      "http://a.com?x=y&siteid=cbindeed&x" => "http://a.com?x=y&x",
      "http://cnn.com?s=Indeed&x" => "http://cnn.com?x",
      "http://cnn.com?utm_source=Indeed&utm_campaign=Indeed#x" => "http://cnn.com?#x",
      "http://cnn.com?a=b&s=Indeed#x" => "http://cnn.com?a=b#x",
      "http://cnn.com?s=Indeed" => "http://cnn.com?",
      "http://cnn.com?a=b&s=Indeed" => "http://cnn.com?a=b",
      "http://cnn.com?a=b&s=Indeed&y=z" => "http://cnn.com?a=b&y=z",
      "http://cnn.com?s=Indeed&y=z" => "http://cnn.com?y=z",
      "http://cnn.com?a=b&s=Indeed#foolala" => "http://cnn.com?a=b#foolala",
      "http://cnn.com?source=indeed.com&x" => "http://cnn.com?x",
      "http://cnn.com?a=b&source=indeed.com#x" => "http://cnn.com?a=b#x",
      "http://cnn.com?source=indeed.com" => "http://cnn.com?",
      "http://cnn.com?a=b&source=indeed.com" => "http://cnn.com?a=b",
      "http://cnn.com?a=b&source=indeed.com&y=z" => "http://cnn.com?a=b&y=z",
      "http://cnn.com?source=indeed.com&y=z" => "http://cnn.com?y=z",
      "http://cnn.com?a=b&source=indeed.com#foolala" => "http://cnn.com?a=b#foolala",

  }
    
  test_expected_io.each{|orig, expected|

      out= clean_indeed_references(orig)
      raise "For #{orig}, expected #{expected} but was #{out}" unless out == expected
  }
  
  puts "Test completed"
end



                      
                      
def set_url_val(old_row, new_row, hdrs_from_file) 
     hit_id = TurkUtils.get_val( TurkUtils::HIT_ID, old_row, hdrs_from_file )
    chosen_url_val = TurkUtils.get_val(CHOSEN + JOB_AD_URL, old_row, hdrs_from_file)
    chosen_url_val = clean_indeed_references(chosen_url_val)
      
     if chosen_url_val.empty?
         puts "Skipping row because no URL val for HITID #{hit_id}"
         return
     end
     
     if chosen_url_val.downcase.include?("indeed")  
       puts "HITID #{hit_id}: The string \"indeed\" is in #{chosen_url_val} "
     end
      
     TurkUtils.set_val(chosen_url_val, dash_to_uscore(JOB_AD_URL), new_row, NEW_HEADERS_F)
end
 
def preprocess_for_work_from_home(row,   hdrs_from_file, hit_id)
      work_from_home_val = TurkUtils.get_val(CHOSEN+TurkUtils::WORK_FROM_HOME, row, hdrs_from_file )
      work_from_home =  (work_from_home_val==TurkUtils::ON)
      city_val = TurkUtils.get_val(CHOSEN+TurkUtils::CITY, row, hdrs_from_file )
      state_val = TurkUtils.get_val(CHOSEN+TurkUtils::STATE, row, hdrs_from_file )
      if (LC_REMOTE_WORK_DESIGNATORS.include?(city_val.downcase.strip)) && !work_from_home 
          puts "Added row to work_from_home board, because city val \"#{city_val}\", hit_id #{hit_id}" 
          TurkUtils.set_val(TurkUtils::ON, CHOSEN+TurkUtils::WORK_FROM_HOME, row, hdrs_from_file )
          work_from_home =  true 
      end
      
      if work_from_home 
        if state_val.strip!="" 
            # Reset val on INPUT row. Setting val on output row would be better, but various error checks below may fail
             TurkUtils.set_val("", CHOSEN+TurkUtils::STATE, row, hdrs_from_file)
             unless TurkUtils::BLANK_VALS.include? state_val.downcase
                puts "Blanking state (was #{state_val}) based on work_from_home board, hit_id #{hit_id} "
             end 
        end
        if city_val!=TurkUtils::TELECOMMUTE
          # Reset val on INPUT row
          TurkUtils.set_val(TurkUtils::TELECOMMUTE, CHOSEN+TurkUtils::CITY, row, hdrs_from_file)
          unless LC_REMOTE_WORK_DESIGNATORS.include?(city_val.downcase.strip)
            puts "Setting city to \"#{TurkUtils::TELECOMMUTE}\" (was \"#{city_val}\") based on work_from_home board, hit_id #{hit_id} "
          end 
       end
     end
    
     return work_from_home
end

def get_chosen_answers(row, arr_of_arr_output, hdrs_from_file)

      hit_id = TurkUtils.get_val( TurkUtils::HIT_ID, row, hdrs_from_file )
 
      if hit_id.empty?
        if row.all?{|item|item.nil? || item.strip.empty?} 
            puts "Skipping empty row"
            
         else
           puts "Skipping row because no HITId: #{row}"
         end
         return
       end
      new_row = [].fill(0, NEW_HEADERS_F.length)
      
      COPY_THESE_VALS.each{|hdr|
        val =  TurkUtils.get_val( hdr, row, hdrs_from_file )
        TurkUtils.set_val(val,  dash_to_uscore(hdr), new_row, NEW_HEADERS_F)
      }
      
    
       work_from_home = preprocess_for_work_from_home(row,   hdrs_from_file, hit_id)
 
       some_board_name_was_set = false
       TurkUtils::BOOLEAN_BASE_NAMES.each{|base_hdr_name|
          chosen_val = TurkUtils.get_val(CHOSEN+base_hdr_name, row, hdrs_from_file )
          raise "bad boolean #{chosen_val} for #{base_hdr_name} with HITID #{hit_id}" unless TurkUtils::valid_onOff_value(chosen_val)
          unless TurkUtils::RELOCATION == base_hdr_name
            board_on = !chosen_val.empty?
            some_board_name_was_set ||= board_on
            if board_on 
              $board_count[base_hdr_name]+=1
            end
          end
          TurkUtils.set_val(chosen_val, dash_to_uscore(base_hdr_name), new_row, NEW_HEADERS_F)
       }
       unless some_board_name_was_set
         puts "Skipping #{hit_id} because no board was set."
         return
       end
 
 
      set_url_val(row, new_row, hdrs_from_file)
     
      upcase_country_code = TurkUtils.get_val(  "#{CHOSEN}country_code", row, hdrs_from_file).upcase
      united_states_or_canada = ["CA",TurkUtils::US].include?(upcase_country_code) 
          
      TXT_BASE_NAMES_EXCEPT_JOB_AD_URL.each{|base_hdr_name|
         
          chosen_val = TurkUtils.get_val(CHOSEN+base_hdr_name, row, hdrs_from_file)
    
         if (base_hdr_name!=TurkUtils::STATE ||  ( united_states_or_canada && !work_from_home) )  #NON-US/CA country can have blank states and work_from_home can have blank states
              if chosen_val.empty?
                   puts "Skipping row because blank #{base_hdr_name} for HITID #{hit_id}"
                  return
              end
          end
              
          TurkUtils.set_val(chosen_val, dash_to_uscore(base_hdr_name), new_row, NEW_HEADERS_F)
      }
   
      unless united_states_or_canada
        puts "Blanking state (was \"#{TurkUtils.get_val(CHOSEN+TurkUtils::STATE, row, hdrs_from_file)}\" for #{hit_id} in country #{upcase_country_code}"
        TurkUtils.set_val("",  TurkUtils::STATE, new_row, NEW_HEADERS_F)
      end
       
      arr_of_arr_output << new_row  
end

 
def main
  test_clean
  input_dir_name = "reviewed_merged_turk_work"
    input_file_name = "merged_turk_work"
  file  = File.new("#{input_dir_name}/#{input_file_name}.csv")
  arr_of_arr_output = TurkUtils.read_file(file,NEW_HEADERS_F, :get_chosen_answers)
  puts "writing #{arr_of_arr_output.length} rows"
  output_name = "ready_for_locale_normalization"
  Dir.mkdir(output_name) unless Dir.exist?(output_name)
  TurkUtils.write_file("#{output_name}/#{output_name}.csv", arr_of_arr_output)
  puts "Ads per board:"
  pp $board_count
end

main()
