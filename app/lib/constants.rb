class Constants 
  
  SHORT_SITENAME ="RightJoin"
  SITENAME = Constants::SHORT_SITENAME + ".io"
  SITENAME_LC = SITENAME.downcase
  FIVEYEAR_ITCH_SHORT_SITENAME ="FiveYearItch"
  FIVEYEAR_ITCH_SITENAME  = Constants::FIVEYEAR_ITCH_SHORT_SITENAME + ".com"
  
  LEAD_REFERRAL_COOKIE = ":lead_referral_share_id"
  
  ERROR_FLASH = "Oops! Something went wrong, we'll be on it right away."
  NOT_AUTHORIZED_FLASH = "Access to that page needs authorization."

  EMPLOYER_TAGLINE = "Connect to Stealth Candidates" 
  CANDIDATE_TAGLINE ="Chat with your professional peers about their workplace"

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  MAX_STRING_LENGTH = 250 #Used for various free-text areas.
  
  SAMPLE_USER_EMAIL_BASE_TEMPLATE = "sample%s@"
  SAMPLE_USER_EMAIL_TEMPLATES = [SITENAME_LC,  FIVEYEAR_ITCH_SITENAME.downcase].map{|domain| SAMPLE_USER_EMAIL_BASE_TEMPLATE + domain}
  CONTACT_EMAIL ="contact@#{SITENAME_LC}"
  ADMIN_EMAIL ="admin@#{FIVEYEAR_ITCH_SITENAME.downcase}"
  FYI_RECRUITER_EMAIL = "jennifer@#{FIVEYEAR_ITCH_SITENAME.downcase}"
  FYI_ADMIN_EMAIL = "robert@#{FIVEYEAR_ITCH_SITENAME.downcase}" 
  
  REMEMBER_TOKEN_INFOINTERVIEW = :remember_token_infointerview
  REMEMBER_TOKEN_AMBASSADOR = :remember_token_ambassador
  
  #Note that  PHONE should be accessed through only through Utils::phone_with_pfx. Maybe move the literal to there.
  PHONE= "718-569-8851"
  
  FYI_CRM_NAME = "Joshua"
  
  NUM_INITIAL_FREE_AMB_CONTACTS = "three"
   
  #USERVOICE_KB_URL = "https://fiveyearitch.uservoice.com/knowledgebase" 
  
  TELECOMMUTE= 'telecommute'
  RELOCATION = 'relocation'
  ANYWHERE = 'anywhere'
  OTHER ='other'
  

  GITHUB = "GitHub"
  TWITTER = "Twitter"
  LINKEDIN = "LinkedIn"
  GOOGLE = "Google"
  FACEBOOK = "Facebook"
 
  SOCIAL_NETWORK_LINKEDIN = LINKEDIN.downcase
  SOCIAL_NETWORK_FACEBOOK = FACEBOOK.downcase
  SOCIAL_NETWORK_TWITTER = TWITTER.downcase
  SOCIAL_NETWORK_GOOGLE = "google_plusone_share"
  SOCIAL_NETWORK_EMAIL = "email"
  
  SHARE_CHANNELS = [Constants::SOCIAL_NETWORK_LINKEDIN, Constants::SOCIAL_NETWORK_FACEBOOK, Constants::SOCIAL_NETWORK_TWITTER, Constants::SOCIAL_NETWORK_GOOGLE, Constants::SOCIAL_NETWORK_EMAIL]
  
  
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
  
   
  COUNTRIES = {COUNTRY_US => LOCALE_EN, COUNTRY_AU => "en-AU", COUNTRY_CA => "en-CA", COUNTRY_UK => "en-GB", COUNTRY_IL=>"en-IL", COUNTRY_IN=>"en-IN"}
 
  TIER_FREE = 1
  TIER_PRO = 2
  TIER_ENTERPRISE = 3
  

  FYI_EPOCH = Time.new(2014, 1, 1, 1, 0, 0)
  
  META_KEYWORDS ="Job, employment, offers, recruiters, peer-to-peer recruiting, employer branding, social recruiting, professionals, software engineers, software developers, stealth candidates"
  META_DESC= "#{Constants::SITENAME} enables peer-to-peer recruiting with employer branding through beautiful, easily sharable job postings" 
end
