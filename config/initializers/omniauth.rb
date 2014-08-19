Rails.application.config.middleware.use OmniAuth::Builder do
   
  OmniAuth.config.on_failure = OmniauthController.action(:auth_failure)
  # To administer OAuth
  # Google, FB, LinkedIn use josh@fiveyearitch.com 
  # GitHub uses admin@fiveyearitch.com   
  # Twitter uses FiveYearItch username to login
  #  
  # Admin URLS
  #    
  #    LI: https://www.linkedin.com/secure/developer
  # 	 Google: https://console.developers.google.com/
  #    (Facebook OAuth not used: configure OAuth at https://developers.facebook.com/apps/, then choose the right 'app' for production/staging/dev)
  #    GitHub: https://github.com/settings/applications/
  #    Twitter: https://apps.twitter.com/
	# Note that FB now has a "Test App" feature so that separate FB apps are no longer needed, but we have that as legacy.
  # Note that Google, Twitter, LI can use the same credential for all  envs.   
  
  provider :google_oauth2, "1042992806296-t0lb9rin0sntfg747ear3jn4ubaarpee.apps.googleusercontent.com", '7kja1cO0nzhw8foTrHrWOTPm'#   should try :access_type => 'online', but this does not work
  provider :twitter, "VJdTZcNLkcPwZv77Ze82Sg","v0Tn4xNAcprh7f5myH5kWPkyKLw2Ei3sVOD5BeHYEb8"
  provider :linkedin, "75vl70u4twsj2d", "UUDo4c2UBg73VhTF"
  
  if Rails.env.development? 
    #For Facebook, use www.lvh.me (But FB OAuth  no longer used -- TODO Delete FB here)
  #  provider :facebook, "187553314770675", "d1559bd453624f580e063dec46c8242f"
    provider :github, "e1ed068e151a13a1bcc7", "809d1e4702086b8d9647c8be9f107d5a0a6eed5d"
  elsif Rails.env.staging?
  # provider :facebook, "191557644370186", "f22fec32f6fe1804b0e6fafa36684e82"
      #Facebook rjstaging.herokuapp.com App ID 733846193334926 App Secret
    provider :github, "20a687fa47b543892b37", "6b81b5e4f2277ae6e531cee94bb8ad5d35e47a97"
  elsif Rails.env.production?
     #Facebook for rightjoin.co.il 806160806080036 App Secret 127082149b0980de8ccb3daad5b0e767
     #Rightjoin.io
  #   provider :facebook,  "498237886965923","5d5c8578f8d2427f1e6ca8626a492f1e"
     #GitHub for  rightjoin.io 
    provider :github, "8a2de1ca6ef401d3e589", "85d13d8a88dea10e5d0f5ffab53ba8a23c7cdb8b"
 
  end
end