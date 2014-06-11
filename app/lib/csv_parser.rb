require 'csv'

class CsvParser
  def self.file_to_hash(filename)
    arr_of_arrs_to_hash CSV.read(filename)
  end
  
  def self.string_to_hash(content)
    arr_of_arrs_to_hash CSV.parse(content)
  end
  
  # Param is actually  arr of hash
  def self.write(path, arrs_to_hash)
    CSV.open(path, "wb") do |csv|
      headers = arrs_to_hash[0].keys if arrs_to_hash.any?
      csv << headers if headers.any?
      
      arrs_to_hash.each do |row_hash|
        row_array = headers.map do |header|
          row_hash[header]
        end
        
        csv << row_array
      end
    end  
  end
  
private
 # This is really Array of arrays to array of hashes
 # So we  could call it arr_of_arrs_to_arr_of_hash
  def self.arr_of_arrs_to_hash(arr_of_arrs)
    arr_of_hashes = []
    header = arr_of_arrs.shift
    arr_of_arrs.each_with_index do |row, i|
      thing = { }
      header.each_with_index do |col, header_index|
        thing[ header[header_index] ] = row[ header_index]
      end
      arr_of_hashes<< thing
    end
    return arr_of_hashes
  end  
end
