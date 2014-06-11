require 'geoip'
require 'net/http'
require 'json'

class LocationUtils
  @@db = GeoIP.new('db/GeoLiteCity.dat')
  def self.locale_by_ip (ip, default_locale = Constants::LOCALE_EN.to_sym)
    locale = nil
    c = @@db.country(ip)
    unless c.nil?
      country = c.country_code2.downcase
      locale_s = Constants::COUNTRIES[country] unless country.blank?
      
      locale = locale_s.to_sym unless locale_s.blank?
    end
    locale ||= default_locale
  end
  
  def self.city_by_ip (ip)
    c = @@db.country(ip)
    res = nil
    res = {:country_code => c.country_code2.downcase, :city_name => c.city_name, :latitude => c.latitude, :longitude => c.longitude} unless c.nil?
    return res
  end
  
  def self.search(place, country_code)
    ret = nil

    url =  "http://nominatim.openstreetmap.org/search?q=#{URI::encode(place)}&format=json&addressdetails=1&limit=1&countrycodes=#{country_code}"
    json_data = Net::HTTP.get(URI.parse(url))
    res = JSON.parse(json_data)
    if res.any?
      obj = res[0]
      city = obj["address"]["city"]
      city ||= obj["address"]["town"]
      city ||= obj["address"]["administrative"]
      city ||= obj["address"]["hamlet"]
      city ||= obj["address"]["county"]
      unless city.blank?
        puts("#{place} >> #{city}, #{obj['address']['state']}")
        ret = {:name => city, :admin_unit => obj["address"]["state"], :longitude => obj["lon"], :latitude => obj["lat"], :country_code => obj["address"]["country_code"]}
      end
    end
  rescue Exception => e
    Rails.logger.error e
  ensure
    return ret
  end
  
  # Input CSV must have at least these 3 columns "city", "state" "country-code: us|gb|au|ca|il|in" 
  # Output will have same rows as input + 3 new columns "location", "latitude", "longitude"
  def self.search_batch(in_csv, out_csv)
    array_of_rows = CsvParser.file_to_hash(in_csv)
    converted_counter = 0
    
    array_of_rows.each do |row|
      begin
        row["location"] = ""
        row["latitude"] = ""
        row["longitude"] = ""        
        
        locale = Constants::COUNTRIES[row["country-code"]]
        raw_location = row["city"].to_s + "" # ensure not reference
        if raw_location == Constants::TELECOMMUTE
          row["location"] = Constants::TELECOMMUTE
          converted_counter += 1
        else
          raw_location << ", #{row['state']}" unless raw_location.blank? || row['state'].blank?
          
          unless locale.blank? || raw_location.blank?
            use_province = I18n.t(:use_province, :locale => locale) 
            loc_obj = LocationUtils.search(raw_location, row["country-code"])
            unless loc_obj.nil?
              row["location"] = (loc_obj[:name] << (use_province == "true" ? ", #{loc_obj[:admin_unit]}" : "")).downcase
              row["latitude"] = loc_obj[:latitude]
              row["longitude"] = loc_obj[:longitude]
              converted_counter += 1
            end
          end
        end
        
        # avoid Encoding::CompatibilityError: incompatible character encodings: ASCII-8BIT and UTF-8 exception
        #row.each do |key, val|
        #  val.encode!("UTF-8", :undef => :replace)
        #end
      rescue  Exception => e
        Rails.logger.error e
      end
    end
    
    CsvParser.write(out_csv, array_of_rows)
    
    puts "Converted #{converted_counter} out of #{array_of_rows.count}"
  end
end
