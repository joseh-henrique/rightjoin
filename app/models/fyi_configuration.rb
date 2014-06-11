class FyiConfiguration < ActiveRecord::Base
  attr_accessible :key, :value
  
  def self.fetch(key)
    obj = FyiConfiguration.find_by_key(key)
    obj.nil? ? nil : obj.value
  end
  
  def self.fetch_with_default(key, default)
    obj = FyiConfiguration.fetch(key)
    obj.nil? ? default : obj
  end
end
