module TurkUtils
    VAL ="Val"
  
    TURKS_PER_HIT = 3
    # We could  change to Val1_ Val2_ Val3_ (with following underline) for consistency.
    # However, we construct VAL+number, so code would break, unless we changed other code.
    VAL1 = "#{VAL}1" 
    VAL2 = "#{VAL}2"
    VAL3 = "#{VAL}3"
    NOT_APPLICABLE="NA"
    BLANK_VALS =[nil, "", "n/a", "nil", NOT_APPLICABLE.downcase, "none", "unknown", "not-selected", "-", "other"]# probably there are no "-".
    
    DEFAULT_COUNTRY_CODE = "default_country_code"
    INPUT = "Input."
    ANSWER = "Answer."
    OTHER= "Other."
    HIT_ID = "HITId"
    ORIG_AD_URL = "orig_ad_url"
    JOB_AD_URL = "job_ad_url"
 
    BLEEDING_EDGE_TECH = "bleeding_edge_tech"
    SEARCH ="search"
    REDO = "redo"
    WORK_FROM_HOME = "work_from_home"
     RELOCATION ="relocation"
     TELECOMMUTE = "telecommute" 
    BOARD_NAMES = [WORK_FROM_HOME, "open_source", "startup", "kegerator",  BLEEDING_EDGE_TECH, "meaningful_jobs"]
    BOOLEAN_BASE_NAMES = BOARD_NAMES + [  RELOCATION]  
    
    STATE = "state"
    TITLE ="title"
    COMPANY = "company"
    CITY ="city"
   
   
   
    TXT_BASE_NAMES = [TITLE, COMPANY,"description", CITY, STATE, "country_code", JOB_AD_URL]
    CHOSEN = "Chosen_"
    ALT = "Alt_"
    ON = "on"
    OFF = ""
    US="US"
    
    NEW_HEADERS_B  = [TurkUtils::DEFAULT_COUNTRY_CODE, TurkUtils::SEARCH, TurkUtils::ORIG_AD_URL] + TurkUtils::BOARD_NAMES
       
    URL_LIST ="url_list"      
    EDITED_URL_LIST ="edited_"+URL_LIST
           
    def self.write_file(fname, arr_of_arr_output, append=false)
      if append
          if File.exists? fname
           arr_of_arr_output = arr_of_arr_output[1..-1]
          end
          filemode="ab"
      else
        filemode="wb"
       end
    
      CSV.open(fname, filemode) do |csv|
 
          puts "writing #{fname} #{append ? "with append":""}" 
          arr_of_arr_output.each { |row|
            csv << row
          }
       end
    end
    
    # TODO: Open file in this function 
    
    def self.read_file(file, new_hdrs, row_func)
      begin
        arr_of_arr_output = []
        arr_of_arr_output << new_hdrs
        puts("reading #{file.path}")
        arr_of_arr_from_file  = CSV.read(file)
        puts "reading #{arr_of_arr_from_file.length} lines"
        header_line_from_file = arr_of_arr_from_file.shift
        arr_of_arr_from_file.each do |row|
           send(row_func, row,arr_of_arr_output,header_line_from_file)
        end
        arr_of_arr_output.delete_if{|row|row.empty?}
        return arr_of_arr_output
      ensure
        file.close 
      end
  end
  
  def self.valid_onOff_value(*vals)
      invalid= vals.select{|val| not [ON, OFF].include?(val) }
      return invalid.empty?
   end

    def self.get_row_from_arr_of_arr(hdr_name, identifier, arr_of_arr)
      hdr_idx = TurkUtils.get_idx(arr_of_arr[0],hdr_name)
      raise "no column #{hdr_name}" unless hdr_idx
      existing = arr_of_arr.select { |row| row[hdr_idx]==identifier}
      
      raise "found #{identifier} twice, which should not occur" if (existing && existing.length>1)
      
      return existing.length==1 ?  existing[0] : nil
    end
    
    def self.set_val( val, hdr_name, row, hdr_names)
        idx = get_idx(hdr_names, hdr_name)
        row[idx] = val
    end
  
    #Return "" for no-val
    def self.get_val( hdr_name,row, hdr_names, raise_exception_if_no_such_col_hdr = true)
      begin
        idx=get_idx(hdr_names, hdr_name)
      rescue Exception =>  e
        if raise_exception_if_no_such_col_hdr
          raise e
        else
          return ""
        end
         
      end
      ret =row[idx]
      ret="" if ret.nil?
      
      return  ret
    end
 
 private
    
    #We could implement an  OO solution, encapsulating row  in a Row class for get_val, set_idx, and get_idx. Also, could give the Row class awareness of Input, Answer, and FromSearchEngine prefixes
    def self.get_idx(hdr_names, name)
        idx = hdr_names.index(name)
        if idx.nil?
          raise "\"#{name}\" not found in #{hdr_names}"
        end  
        return idx
    end 
end