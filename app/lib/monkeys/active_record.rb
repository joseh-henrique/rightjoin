module ActiveRecord
  class Base
    def self.to_conditions_str(conditions, separator)
      left = []
      right = []
      conditions.each do |x|
        if x.kind_of?(Array)
          left << x.first
          right << x.last
        else
          left << x
        end
      end
      
      full_conditions = [left.join(separator)] + right
      conditions_str = sanitize_conditions(full_conditions)
      
      return conditions_str 
    end
  end
end
