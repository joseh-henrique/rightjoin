require 'net/http'

class DbFeeder
  # URL must point to a CSV file (HTTPS is not supported!)
  # make sure controller handles exceptions
  def self.feed_from_url(url)
    csv_content = Net::HTTP.get(URI.parse(url))
    rows = CsvParser.string_to_hash(csv_content)
    
    rows.each_with_index do |row, i|
      yield row, i
    end
    
    return rows
  end
  
  # CSV must have a "model" column containing record's model name
  # Note: this method uses mass assignment in create!, so it's only usable in a rare case when all model fields are attr_accessible  
  def self.simple_feed_from_url(url)
    self.feed_from_url(url) do |row, i|
      begin
        model_name = attr_list.delete("model")
        if model_name.nil?
          raise "Empty or missing model name"
        else
          obj = eval(model_name.capitalize).create!(attr_list)
          puts "Created record #{i+1}, model: #{model_name}, #{attr_list.to_s}"
        end
      rescue Exception => exc
        puts "Failed to create record #{i+1}, #{attr_list.to_s}: #{exc.message}"
      end
    end
  end
end
