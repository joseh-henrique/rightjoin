Rails.application.config.middleware.use OmniAuth::Builder do
   
  OmniAuth.config.on_failure = OmniauthController.action(:auth_failure)
  
  # josh@fiveyearitch.com: OAuth account for Google, FB, LinkedIn 
  # admin@fiveyearitch.com for  Twitter , GitHub
  #                                                           
 
  provider :twitter, "VJdTZcNLkcPwZv77Ze82Sg","v0Tn4xNAcprh7f5myH5kWPkyKLw2Ei3sVOD5BeHYEb8"
  provider :google_oauth2, "1042992806296-t0lb9rin0sntfg747ear3jn4ubaarpee.apps.googleusercontent.com", '7kja1cO0nzhw8foTrHrWOTPm'#   should try :access_type => 'online', but this does not work 
  provider :linkedin, "75vl70u4twsj2d", "UUDo4c2UBg73VhTF"
  
  if Rails.env.development? 
    #For Facebook, use www.lvh.me
    provider :facebook, "187553314770675", "d1559bd453624f580e063dec46c8242f"
    provider :github, "e1ed068e151a13a1bcc7", "809d1e4702086b8d9647c8be9f107d5a0a6eed5d"
  elsif Rails.env.staging?
    provider :facebook, "191557644370186", "f22fec32f6fe1804b0e6fafa36684e82"
      #Facebook rjstaging.herokuapp.com App ID 733846193334926 App Secret
    provider :github, "20a687fa47b543892b37", "6b81b5e4f2277ae6e531cee94bb8ad5d35e47a97"
    # Github rjstaging  30a8be591ab24d188933 Client Secret 9417dc48f6a784fa6a95167e87265bfcf40c86b0
  elsif Rails.env.production?
    # Facebookfiveyearitch.com "248970581928512", "3f57eb5b65130c596dd60fa0ec8af8dc"
     #Facebook rightjoin.co.il 806160806080036 App Secret 127082149b0980de8ccb3daad5b0e767
     #Rightjoin.io
     provider :facebook,  "498237886965923","5d5c8578f8d2427f1e6ca8626a492f1e"
     
    #Github fiveyearitch.com "84e3a1ea8a23296f880b", "acdb8876261e64b784e35fbf7348de2023a7f8c3"
    #Github rightjoin.co.il c60fe06efdf007fba56a  Client Secret aa39cd195b9d01508c20687a057aae59f70bbf54
    #Github rightjoin.io 
    provider :github, "8a2de1ca6ef401d3e58", "85d13d8a88dea10e5d0f5ffab53ba8a23c7cdb8b"
    
  end
end