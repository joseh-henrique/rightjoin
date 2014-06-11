class DistanceUtils 
  DEFAULT_DISTANCE = 60 # miles
  
  def self.deg2rad(d)
      (d/180.0)*Math::PI
  end
  
  def self.rad2deg(r)
      (r/Math::PI)*180
  end

  def self.bounding_box(latitude, longitude, distance = DEFAULT_DISTANCE, unit = :mi)
    # bearings
    due_north = 0
    due_south = 180
    due_east = 90
    due_west = 270
    northmost = coord_in_distance(latitude, longitude, due_north, distance, unit)[:latitude]
    southmost = coord_in_distance(latitude, longitude, due_south, distance, unit)[:latitude]
    eastmost = coord_in_distance(latitude, longitude, due_east, distance, unit)[:longitude]
    westmost = coord_in_distance(latitude, longitude, due_west, distance, unit)[:longitude]
    
    #return 2 points NW corner and SE corner
    {:northmost => northmost, :westmost => westmost ,:southmost => southmost, :eastmost => eastmost}
  end
  
  def self.coord_in_distance(latitude, longitude, bearing, distance = DEFAULT_DISTANCE, unit = :mi)
    if unit == :mi
        radius = 3963.1
    elsif unit == :km
        radius = 6371.0
    end
    
    #  New latitude in degrees.
    new_latitude = rad2deg(Math::asin(Math::sin(deg2rad(latitude)) * Math::cos(distance / radius) + Math::cos(deg2rad(latitude)) * Math::sin(distance / radius) * Math::cos(deg2rad(bearing))))
        
    #  New longitude in degrees.
    new_longitude = rad2deg(deg2rad(longitude) + Math::atan2(Math::sin(deg2rad(bearing)) * Math::sin(distance / radius) * Math::cos(deg2rad(latitude)), Math::cos(distance / radius) - Math::sin(deg2rad(latitude)) * Math::sin(deg2rad(new_latitude))))
    
    {:latitude => new_latitude, :longitude => new_longitude}
  end
end
