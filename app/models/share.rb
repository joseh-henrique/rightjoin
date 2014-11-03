class Share < ActiveRecord::Base
  validates :network, :presence => true
  
  belongs_to :ambassador
  belongs_to :job
  
  SOCIAL_NETWORK_LINKEDIN = Constants::LINKEDIN.downcase
  SOCIAL_NETWORK_FACEBOOK = Constants::FACEBOOK.downcase
  SOCIAL_NETWORK_TWITTER = Constants::TWITTER.downcase
  SOCIAL_NETWORK_GOOGLE = "google_plusone_share"
  SOCIAL_NETWORK_EMAIL = "email"
  SOCIAL_NETWORK_SHARE_URL ="share_url"
  CHANNEL_TAB = Constants::RIGHT_JOIN_TAB.downcase.tr(' ','_')
  CHANNEL_BOARD = Constants::RIGHT_JOIN_BOARD.downcase.tr(' ','_')
  CHANNEL_REVERSE_BOARD = Constants::RIGHT_JOIN_REVERSE_BOARD.downcase.tr(' ','_')
  CHANNEL_OTHER = Constants::OTHER.downcase
  
  # NEVER change index values  
  DISTRIBUTION_CHANNEL_INFO = {
    SOCIAL_NETWORK_LINKEDIN => {:index => 0, :display_name => Constants::LINKEDIN, :social_share => true},
    SOCIAL_NETWORK_FACEBOOK => {:index => 1, :display_name => Constants::FACEBOOK, :social_share => true},
    SOCIAL_NETWORK_TWITTER => {:index => 2, :display_name => Constants::TWITTER, :social_share => true},
    SOCIAL_NETWORK_GOOGLE => {:index => 3, :display_name => Constants::GOOGLE, :social_share => true},
    SOCIAL_NETWORK_EMAIL => {:index => 4, :display_name => Constants::EMAIL, :social_share => true},
    CHANNEL_TAB => {:index => 10, :display_name => Constants::RIGHT_JOIN_TAB, :social_share => false},
    CHANNEL_BOARD => {:index => 20, :display_name => Constants::RIGHT_JOIN_BOARD, :social_share => false},
    CHANNEL_REVERSE_BOARD => {:index => 30, :display_name => Constants::RIGHT_JOIN_REVERSE_BOARD, :social_share => false},
    CHANNEL_OTHER => {:index => 40, :display_name => Constants::OTHER, :social_share => false}
  }
  
  # provides flexibility to change the format in the future
  VERSION_MARK = "a" # must be exactly 1 letter
  
  def self.build_hash(channel_name, ambassador_id = 0)   
    map = Share::DISTRIBUTION_CHANNEL_INFO[channel_name]
    
    return "" if map.nil?
    
    check_sum = calculate_checksum([map[:index], ambassador_id])
    return "#{VERSION_MARK}#{check_sum.to_s(16)}.#{map[:index].to_s(16)}.#{ambassador_id.to_s(16)}"
  end
  
  # returns nil if hash string is invalid
  def self.parse_hash(str)
    res = nil
    
    unless str.blank?
      str.sub!(/^#/, '')
      parts = str.split(".")
      if parts.length >= 3
        check_sum_part = parts[0]
        if check_sum_part.start_with?(VERSION_MARK)
          check_sum_part.slice!(0)
          channel_index, ambassador_id = parts[1].to_i(16), parts[2].to_i(16)
          check_sum = calculate_checksum([channel_index, ambassador_id])
          if check_sum == check_sum_part.to_i(16)
            channel_name = channel_by_index(channel_index)
            res = {:channel => channel_name, :ambassador_id => ambassador_id} unless channel_name.nil?
          end
        else # old format with no checksum
          channel_index, ambassador_id = parts[0].to_i(16), parts[1].to_i(16)
          channel_name = channel_by_index(channel_index)
          res = {:channel => channel_name, :ambassador_id => ambassador_id} unless channel_name.nil?  unless channel_name.nil?
        end
      end
    end
    
    return res
  end
  
private
  
  def self.calculate_checksum(arr)
    sum = arr.inject(:+)
    (sum * (sum + 3)) % 251
  end
  
  def self.channel_by_index(index)
    @@channel_by_index_map ||= DISTRIBUTION_CHANNEL_INFO.inject({}){|new_hash, (k,v)| new_hash[v[:index]] = k; new_hash}
    @@channel_by_index_map[index]
  end
end
