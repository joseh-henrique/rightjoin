# Documentation: 
# See https://docs.google.com/document/d/1-gzWQwPFz4frHKpTMInges9AqAyXpCsywKJj7pXfHgM/edit for documentation

require 'csv'
require_relative  'turk_utils'


URL = "Url" 
   
NEW_HEADERS_B = TurkUtils::NEW_HEADERS_B  

$num_duplicates =0

def read_files(files, country= TurkUtils::US )
  arr_of_arr_output = []
  arr_of_arr_output << NEW_HEADERS_B

  files.each {|f|
      read_file(f, arr_of_arr_output,country)
  }  
 
  return arr_of_arr_output
end


def set_on(row, board)
    TurkUtils::set_val( TurkUtils::ON, board, row, NEW_HEADERS_B)
     
end

def process_row(row, arr_of_arr_output, header_line_from_file, boardname, country)
    url =  TurkUtils::get_val( URL,row, header_line_from_file )
    puts "Ends with semicolon: #{url}" if url.end_with?(";")
    
    unless url.empty?
       existing_row = TurkUtils.get_row_from_arr_of_arr(TurkUtils::ORIG_AD_URL, url, arr_of_arr_output)
       raise "Not supporting non-Indeed searches now: #{url}"  unless url.include?("indeed.com")# non-indeed URLs already cleansed
        if existing_row #merge duplicates
            $num_duplicates+=1
            set_on(existing_row,boardname)
        elsif url.include?("indeed.com/rc/") 
 
          
            expect = country=='us' ? "www"  :country
            country_url = url.split(/[\/.]/)[2]
            if country_url!=expect
              puts "Warning! For country #{country}, expect #{expect} component in URL #{url} but was #{country_url}"
            end
            new_row = [country,boardname,  url]
            new_row.fill("", new_row.length...NEW_HEADERS_B.length)
            set_on(new_row, boardname) 
            arr_of_arr_output << new_row
        end 
    end
end

def read_file(file, arr_of_arr_output, country = TurkUtils::US)
  begin
      boardname = File.basename(file,  ".*")
      
      logline= "reading #{file.split("/")[-1]} -- "
      arr_of_arr_from_file  = CSV.read(file, :col_sep => ";")
      logline+= "#{arr_of_arr_from_file.length} raw lines"
      header_line_from_file = arr_of_arr_from_file.shift
      unless header_line_from_file.include?(URL)  
        arr_of_arr_from_file.unshift header_line_from_file
        logline += "; added header"
        header_line_from_file = ["Url", "Google pagerank", "Google index", "SEMrush links", "SEMrush linkdomain", "Bing index", "Alexa rank", "Webarchive age", "Whois", "Page source", "SEMrush Rank", "SEMrush SE Traffic price"]
      end
      puts logline

      arr_of_arr_from_file.each do |row|
         process_row(row,arr_of_arr_output, header_line_from_file, boardname, country)
      end
    rescue  
      puts "Error in file #{file}"
      raise 
    end
    #TODO count the number of items in each board of arr_of_arr_output
    #Delete "excess" rows for each board, where the goal is to distribute the items as evenly as possible  across the boards so that there are 60 US rows. If there are <10 rows for a given board, that is of course not possible. 
end

output_dir  = TurkUtils::URL_LIST
 
  # localized_output_filename = output_dir  + ext
# puts localized_output_filename
Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
output_file_path = "#{output_dir}/#{output_dir}.csv"
File.delete(output_file_path) if File.exists? output_file_path
dirs =Dir.glob("seoquake.*")

dirs.each {|dir|
  files = Dir.glob("#{dir}/*.csv")
  expect= TurkUtils::BOARD_NAMES.sort
  actual =  files.map{|f| File.basename(f,  ".*")}.sort

  missing  = expect - actual
  extra = actual - expect 
  puts "in #{dir }, extra files are #{extra}; missing are #{missing}" unless extra.empty? && missing.empty?  
 
  ext=  File.extname(dir)
  country=ext[1..-1]  
  
  arr_of_arr_output = read_files(files, country)
 
  puts "#{$num_duplicates} duplicates"
  puts "writing #{arr_of_arr_output.length} valid job-ad lines" 
 
  TurkUtils.write_file(output_file_path, arr_of_arr_output, true)
  puts "----------------------\n"
}

 
 

