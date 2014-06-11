 # Take a list of Indeed URLs in redo.txt. For each of these, select the relevant row in edited_url_list and write a new file with just these rows.
 # If Indeed URLs are repeated, then the rows will be repeated in the output.  
require 'csv'
require_relative  'turk_utils'

REDO =TurkUtils::REDO
URL_LIST =TurkUtils::URL_LIST
EDITED_URL_LIST=TurkUtils::EDITED_URL_LIST

merged_seo="#{URL_LIST}/#{EDITED_URL_LIST}.csv"
arr_of_arr_from_merged_seoquake_file  = CSV.read(merged_seo)
 
arr_of_arr_filtered_seo_file =[]
arr_of_arr_filtered_seo_file<<TurkUtils::NEW_HEADERS_B  

File.open("#{REDO}/#{REDO}.txt" ).each do |line|
  line.chomp!
  
  row=TurkUtils::get_row_from_arr_of_arr( TurkUtils::ORIG_AD_URL, line, arr_of_arr_from_merged_seoquake_file)
  if row.nil?
    puts "Line to be redone is not in the original merged seoquake file: #{line}" 
    next 
  end
  arr_of_arr_filtered_seo_file << row
end

TurkUtils::write_file( "#{URL_LIST}/#{EDITED_URL_LIST}_another_time_around.csv", arr_of_arr_filtered_seo_file)
    
puts "NEXT STEP: Run this through Turk task, then download CSV and CHECK FOR MISSING COLUMNS! 
ANY columns that did not have at least one \"on\" value will be  missing.  Add these columns as needed"
