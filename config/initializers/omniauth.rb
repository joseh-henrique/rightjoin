Rails.application.config.middleware.use OmniAuth::Builder do
   
  OmniAuth.config.on_failure = OmniauthController.action(:auth_failure)
  # Admin  
  #    LI (user josh@fiveyearitch.com) https://www.linkedin.com/secure/developer
  # 	 Google (user josh@fiveyearitch.com)  https://console.developers.google.com/
  #    GitHub ( user admin@fiveyearitch.com) https://github.com/settings/applications/
  #    Twitter (user FiveYearItch,admin@fiveyearitch.com) https://apps.twitter.com/
  #    (Facebook OAuth not used, but we were logging in with (user josh@fiveyearitch.com.)
   
  provider :google_oauth2, "1042992806296-t0lb9rin0sntfg747ear3jn4ubaarpee.apps.googleusercontent.com", '7kja1cO0nzhw8foTrHrWOTPm'#   should try :access_type => 'online', but this does not work
  provider :twitter, "VJdTZcNLkcPwZv77Ze82Sg","v0Tn4xNAcprh7f5myH5kWPkyKLw2Ei3sVOD5BeHYEb8"
  provider :linkedin, "75vl70u4twsj2d", "UUDo4c2UBg73VhTF"
  
  if Rails.env.development? 
    provider :github, "e1ed068e151a13a1bcc7", "809d1e4702086b8d9647c8be9f107d5a0a6eed5d"
  elsif Rails.env.staging?
    provider :github, "20a687fa47b543892b37", "6b81b5e4f2277ae6e531cee94bb8ad5d35e47a97"
  elsif Rails.env.production?
     #GitHub for  rightjoin.io 
    provider :github, "8a2de1ca6ef401d3e589", "85d13d8a88dea10e5d0f5ffab53ba8a23c7cdb8b"
 
  end
end