class Constants 
  
  SHORT_SITENAME ="RightJoin"
  SITENAME = Constants::SHORT_SITENAME + ".io"
  SITENAME_LC = SITENAME.downcase
  SITENAME_IL_LC = SHORT_SITENAME.downcase + ".co.il"
  TWITTER_USER = "@" + SHORT_SITENAME


  FIVEYEARITCH_SHORT_SITENAME ="FiveYearItch"
  FIVEYEARITCH_SITENAME  = "#{FIVEYEARITCH_SHORT_SITENAME}.com"
  
  LEAD_REFERRAL_COOKIE = ":lead_referral_share_id"
  
  ERROR_FLASH = "Oops! Something went wrong, we'll be on it right away."
  NOT_AUTHORIZED_FLASH = "Access to that page needs authorization."

  EMPLOYER_TAGLINE = "Connect to Stealth Candidates" 
  CANDIDATE_TAGLINE = "Chat with your professional peers about their workplace"
  AMBASSADOR_TAGLINE = "Find some great future colleagues" 

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  MAX_STRING_LENGTH = 250 #Used for various free-text areas.
  
  SAMPLE_USER_EMAIL_BASE_TEMPLATE = "sample%s@"
  SAMPLE_USER_EMAIL_TEMPLATES = [SITENAME_LC,  FIVEYEARITCH_SITENAME.downcase].map{|domain| SAMPLE_USER_EMAIL_BASE_TEMPLATE + domain}
  CONTACT_EMAIL ="contact@#{SITENAME_LC}"
  ADMIN_EMAIL ="admin@#{FIVEYEARITCH_SITENAME.downcase}"
  RECRUITER_EMAIL_FOR_TURK_ADS = "jennifer@#{FIVEYEARITCH_SITENAME.downcase}"
  ADMIN_CONSOLE__USER = "robert@#{FIVEYEARITCH_SITENAME.downcase}" 
  
  REMEMBER_TOKEN_INFOINTERVIEW = :remember_token_infointerview
  REMEMBER_TOKEN_AMBASSADOR = :remember_token_ambassador
  

   
  TELECOMMUTE= 'telecommute'
  RELOCATION = 'relocation'
  ANYWHERE = 'anywhere'
  OTHER_JOB ='other'# Probably not in use; originally used only for signing up from  the 'quiz'
  

  GITHUB = "GitHub"
  TWITTER = "Twitter"
  LINKEDIN = "LinkedIn"
  GOOGLE = "Google"
  FACEBOOK = "Facebook"
  EMAIL = "Email"
  OTHER_SHARING_CHANNEL ="Other"
 
  SOCIAL_NETWORK_LINKEDIN = LINKEDIN.downcase
  SOCIAL_NETWORK_FACEBOOK = FACEBOOK.downcase
  SOCIAL_NETWORK_TWITTER = TWITTER.downcase
  SOCIAL_NETWORK_GOOGLE = "google_plusone_share"
  SOCIAL_NETWORK_EMAIL = "email"
  SOCIAL_NETWORK_OTHER ="other"
  SOCIAL_NETWORK_SHARE_URL ="share_url"
  
  SHARE_CHANNELS = [SOCIAL_NETWORK_LINKEDIN, SOCIAL_NETWORK_FACEBOOK, SOCIAL_NETWORK_TWITTER, SOCIAL_NETWORK_GOOGLE, SOCIAL_NETWORK_EMAIL]
  
  SHARE_CHANNEL_DISPLAY_NAMES = {
      SOCIAL_NETWORK_LINKEDIN => LINKEDIN,
      SOCIAL_NETWORK_FACEBOOK =>  FACEBOOK,
      SOCIAL_NETWORK_TWITTER =>TWITTER,
      SOCIAL_NETWORK_GOOGLE => GOOGLE,
      SOCIAL_NETWORK_EMAIL => EMAIL,
      SOCIAL_NETWORK_OTHER => OTHER_SHARING_CHANNEL
    }
  
  OAUTH_TYPE_INSIDER = "insider"
  OAUTH_TYPE_CONTACT = "contact"
    
  ELIPSIS = ", ..."
  
  # en, in-IL, en-IN etc are locale.
  # However, the :locale used in URLs should receive a country_code value, as below.
  LOCALE_EN = "en"
  
  # us, au, il, uk etc are country_code
  # the :locale used in URLs should receive one of these country_code values 
  COUNTRY_US = "us"
  COUNTRY_AU = "au"
  COUNTRY_CA = "ca"
  COUNTRY_UK = "uk"
  COUNTRY_GB = "gb" # Not used!
  COUNTRY_IL = "il"
  COUNTRY_IN = "in"
  
  #TODO encapsulate these hashes in a function.
  COUNTRIES = {
    COUNTRY_US => LOCALE_EN, COUNTRY_AU => "en-AU", COUNTRY_CA => "en-CA", 
    COUNTRY_UK => "en-GB",  
    COUNTRY_IL=>"en-IL", COUNTRY_IN=>"en-IN"}
 
  COUNTRIES_INCLUDING_NON_STANDARD_ABBREV = COUNTRIES.clone
  COUNTRIES_INCLUDING_NON_STANDARD_ABBREV[COUNTRY_GB] = "en-GB";  
 
  TIER_BASIC = 1
  TIER_PRO = 2
  TIER_ENTERPRISE = 3
  

  FYI_EPOCH = Time.new(2014, 1, 1, 1, 0, 0)
  
  META_KEYWORDS ="Job, employment, offers, recruiters, peer-to-peer recruiting, employer branding, social recruiting, professionals, software engineers, software developers, stealth candidates"
  META_DESC= "#{Constants::SITENAME} enables peer-to-peer recruiting with employer branding through beautiful, easily sharable job postings"
  
  REPRESENTATIVE_LOGO = "misc/all_14_with_bg.png"
  
  GOOGLE_MAPS_API_KEY = "AIzaSyDyahJvNDCBGb_IOg1dygchRrAb-uhsrNY"  #this  key is not in use AIzaSyDEQYS0hqC7Gyw0KDgmWBf95U_WLeS7q2E
end
