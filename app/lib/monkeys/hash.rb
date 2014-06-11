require 'uri'

class Hash
  def self.from_url_params(url_params)
    
    return {} if url_params.nil?
     
    result = {}.with_indifferent_access
    url_params.split('&').each do |element|
      element = element.split('=')
      result[URI.unescape(element[0])] = URI.unescape(element[1])
    end
    result
  end
end