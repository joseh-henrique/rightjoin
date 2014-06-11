require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'singleton'

class RssLoader
  include Singleton

  def initialize
    # The @last_rss global is for caching blog entries in-memory.
    # In dev, Ruby classes and globals like this one are reinited on each request.   
    @last_rss= Time.at(946702800) # January 1, 2000
    @rss = nil
  end
  
  def load_blog_feed_if_needed
    time_since_load = Time.now - @last_rss 
    if !@rss || time_since_load > 10*60
      #URL is case sensitive
      source = "http://blog.#{Constants::SITENAME_LC}/feeds/posts/default?alt=rss"
      @last_rss = Time.now
      content = "" 
      open(source) { |s| content = s.read }
      @rss = RSS::Parser.parse(content, false)
      if @rss.nil?
        Rails.logger.error "Failed to load the blog feed"
      else
        ActionController::Base.new.expire_fragment("blog_feed")
      end
    end
    rescue Exception => e
      Rails.logger.error "Exception loading the blog feed: #{e.message}"
  end    
  
  def rss_feed()
    # nil-pad to length 4, only meaningful when loading a very new blog.
    if @rss
      res = @rss.items[0..3]
      res[3]||=nil #pads out to idx 3 
    else
      res=[nil,nil,nil,nil]
    end
    
    return res 
  end
end