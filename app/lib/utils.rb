require 'digest'
require 'htmlentities'

class Utils 
  def self.format_date(date)
    if date.today?
      "Today"
    elsif Time.now.year == date.year
      "#{date.day} #{date.strftime("%b")}"
    else
      %Q(#{date.day} #{date.strftime("%b")}, #{date.year})
    end
  end
  
  def self.hash_key(k)
    key = Digest::SHA2.hexdigest(k)
    key = key.slice(0, 6)
    key_i = key.to_i(16)
    key_i.to_s(32)
  end
 
   # This method was extracted 
   # 1. to allow commenting-out of actual delivery during development,
   # 2. to give a single breakpoint, 
   # 3. and to give debug dump files.   
   #
   # (The standard way to block  delivery in dev is to set config.action_mailenew_msg_Sun_11.41.49.2.txtr.delivery_method = :test in environment.rb
   # and there are other tools like mailtrap.io.)
   def self.deliver(email_msg)
      email_msg.deliver

      if false and  # Add hashmark between 'if' and 'false to enable writing debug files to disk  
          Rails.env.development?    
            email_msg.body.parts.each do |part|
                if part.mime_type == "text/html"
                  ext="html"
                elsif part.mime_type == "text/plain"
                  ext ="txt" 
                end
                txt= part.body.to_s
                now_ =Time.now
                deciseconds=now_.strftime("%L").to_i/100
                time_s= now_.strftime("%a_%H.%M.%S.#{deciseconds}")
                to = email_msg.to.to_s.gsub("@","_").gsub(/[\[\]"]/ , "")
                fn =Dir.home+"/msg_#{time_s}_#{to}." + ext
                File.open(fn, "w:UTF-8") {|f| f.write(txt) }  
            end
      end
   end
  
  def self.html_unescape(s)
    coder = HTMLEntities.new  
    ret=  coder.decode("'"+s+"'") # Quotes are needed for decode
    ret = ret[1...-1]
    ret 
  end
  
  
  def self.last_word_emphatic(sentence)
    words = sentence.split
    ret = words[0...-1].join(" ") +" <em>" + words[-1] +"</em>"
    return ret.html_safe
  end
  
  def self.html_to_txt(txt)
    txt = txt.gsub("</p>","\n\n").gsub("<br>" ,"\r\n").gsub("<br/>","\n\n")
    txt = txt.gsub(/<a\s+href\s*=\s*["'](.+?)["']>(.+?)<\/a>/, "\\2 ( \\1 )")
    txt = txt.gsub("<hr>", "________________________________________")
    ActionView::Base.full_sanitizer.sanitize(txt)
  end
  
  # This class exists so we can use TextHelper's module-instance method in the class method below. Probably there is a way to do it with metaprogramming, but this seems to work.
  class Truncator
    include  ActionView::Helpers::TextHelper 
  end

  def self.truncate(desc, length = 90)
    truncated = desc #may be overwritten by shortened version
    
    if desc.length > length 
      t = Truncator.new 
      truncated = t.truncate(desc, :length => length, :separator => ' ')
      truncated = t.truncate(desc, :length => length) if truncated == "..."
    end
    return truncated
  end

  def self.truncated_plaintext(desc, options={}  )
    defaults = { :length => 90, :encode => true  }
    options = defaults.merge(options)
    len = options[:length]
    encode = options[:encode]
        
    coder = HTMLEntities.new
    s = coder.decode(desc.gsub(/<\/?.*?>/, " "))
    truncated = s # value of 'truncated' variable may be overwritten by shortened version
    
    if s.length > len 
      t = Truncator.new 
      truncated = t.truncate(s, :length => len, :separator => ' ')
      truncated = t.truncate(s, :length => len) if truncated == "..."
    end
    if encode
      retval = coder.encode(truncated)
    else
      retval = truncated
    end
    retval.strip!
    return retval
  end


  # The line must hold max chars. If elipsis is used, 4 chars will be subtracted
  def  self.truncate_html(txt_tag_pairs, max, use_elipsis_if_needed)
    max = max - Constants::ELIPSIS.length if use_elipsis_if_needed
    def self.append(html_str, plaintxt_str, html_delta, plaintext_delta )
      return html_str + html_delta, plaintxt_str + plaintext_delta 
    end

     html_str = ""
     plaintxt_str = "" # We could just count length as integer. The actual plaintext string is not needed--for debug only. 
    
     txt_tag_pairs.each do |pair|
       txt = pair[0]
       cls = pair.length==1 ? nil : pair[1]
       
       if  plaintxt_str.length + txt.length > max
          sfx = use_elipsis_if_needed ? Constants::ELIPSIS : ""
          cmaspc=", " # comma-space
          cmaspc_len = cmaspc.length
          # Next, delete final comma before adding suffix. We do this whether the suffix is elipsis or blank, to avoid ending in comma  
          if html_str[-cmaspc_len, cmaspc_len] == cmaspc
            html_str=html_str[0 ... -cmaspc_len]
            puts "Mismatched " + html_str +" and " +plain_text_str unless plaintxt_str[-cmaspc_len, cmaspc_len]==cmaspc
            plaintext_str = plaintxt_str[0 ... cmaspc_len]
          end
          html_str, plaintxt_str = append(html_str, plaintxt_str, sfx, sfx)
          break
       else
         if cls.blank?  
            html_str, plaintxt_str = append(html_str, plaintxt_str, txt, txt ) 
         else
            raise "Illegal CSS class \"#{cls}\"" unless cls =~  /^[_a-zA-Z]+[-_a-zA-Z0-9]*$/
            html_str, plaintxt_str = append(html_str, plaintxt_str, "<span class='#{cls}'>#{txt}</span>",txt) # HTML markup adds 22 chars  +cls.length
         end
       end
    end

    html_str
  end
  
   def self.monthly_price(tier)
       sym ="monthly_tier_#{tier}_price".to_sym
       val= I18n.t(sym)
      return val.to_i
   end
  
  def self.monthly_price_s(tier)
    val = monthly_price(tier)
    if val==0
      return "Free"
    else
      return Utils::format_currency(val.to_s)
    end
    
  end
  
  def self.format_currency(val, locale = I18n.locale)
    ActionController::Base.helpers.number_to_currency(val, :unit => I18n.t(:currency_unit, :locale => locale), :delimiter => I18n.t(:thousands_delimiter, :locale => locale), :precision => 0)
  end  
  
  def self.reference_num(obj, scramble = false)
    factor = scramble ? 2.79 : 1 # Use a magic number to scramble the ref num
    obj.id.to_s(16) + "%05x" % (obj.created_at.to_time.seconds_since_midnight * factor)
  end
  
  def self.find_by_reference_num(model, ref_num, scramble = false)
    id = ref_num[0..-6].hex
    obj = model.find_by_id(id)
    raise "Object not found" if obj.nil?
    raise "Wrong checksum" if obj.reference_num(scramble) != ref_num
    
    obj
    
    rescue Exception => e
      raise "Wrong reference number #{ref_num}"
  end
  
  def self.call_us_str(locale)
    res = ""
    if locale == Constants::COUNTRIES[Constants::COUNTRY_US]
      res = ", or call us at #{phone_with_pfx}"
    end
    return res
  end  
 
  
  #This should be in helper, but it is here because  it must be accessed from fyi_mailer
  def self.phone_with_pfx
    return "#{I18n.t(:intl_phone_pfx)}#{Constants::PHONE}"
  end  
   
   def self.items_to_counts(array)
    ret = array.group_by{|o|o}.map{|item,copies|[item, copies.length]}
    return ret
   end
   
  # Returns the top n items, by the number of times they appear in the array, as an array of pairs [item,count]
  # For example, top(['a','b','c', 'd','e','f', 'b','c','b'],2) will return [['b',3],['c',2]]  
  def self.top(array, n)
    items_to_counts = items_to_counts(array)
    sorted = items_to_counts.sort_by{|key_val|key_val[1]}.reverse
    return sorted[0..n]
  end
  
  def self.to_bool(o)
    !!(o.to_s.strip =~ /^(true|t|yes|on|y|1)$/i)
  end
  
  def self.format_natural_number(number, thousands_separator, digit_class, separator_class)
    plain_text = number.to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1#{thousands_separator}").reverse
    res = ""
    plain_text.each_char do |c|
      elem_class = c == thousands_separator ? separator_class : digit_class
      res << "<span class='#{elem_class}'>#{c}</span>"
    end
    return res
  end
end


