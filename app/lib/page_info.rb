 class PageInfo 
  # candidates
  WELCOME = {:id => "pg-welcome", :title => "Welcome", :intended_for => :employee}
  REGISTER = {:id => "pg-register", :title => "Software engineers sign-up here", :intended_for => :employee}
  ABOUT = {:id => "pg-about", :title => "About our services for software engineers", :intended_for => :employee}
  PRIVACY = {:id => "pg-privacy", :title => "Privacy policy", :intended_for => :employee }
  HOME = {:id => "pg-home", :title => "Home for software engineers", :intended_for => :employee}
  INTERVIEWS = {:id => "pg-interviews", :title => "Pinging you about a job opportunity", :intended_for => :employee}  
  EDIT = {:id => "pg-edit", :title => "Edit profile", :intended_for => :employee}
  FAQ = {:id => "pg-faq", :title => "FAQ for software engineers", :intended_for => :employee }
  ENGINEERS = {:id => "pg-search", :title => "Engineers", :intended_for => :employee} 
  JOBS = {:id => "pg-jobs", :title => "Jobs", :intended_for => :employee}
 
  # employers
  EMPLOYER_WELCOME = {:id => "pg-welcome", :title => "Employers", :intended_for => :employer}
  EMPLOYER_GET_STARTED = {:id => "pg-get-started", :title => "Get started", :intended_for => :employer}
  EMPLOYER_PRIVACY = {:id => "pg-privacy", :title => "Privacy policy", :intended_for => :employer }
  EMPLOYER_HOME = {:id => "pg-home", :title => "Employer home", :intended_for => :employer}  
  EMPLOYER_RECOMMENDED = {:id => "pg-recommended", :title => "Leads recommended for you", :intended_for => :employer}
  EMPLOYER_LEADS = {:id => "pg-leads", :title => "Leads for your positions", :intended_for => :employer}
  EMPLOYER_NEW_POSTING = {:id => "pg-new-posting", :title => "New job posting", :intended_for => :employer}
  EMPLOYER_EDIT_POSTING = {:id => "pg-edit-posting", :title => "Edit job posting", :intended_for => :employer}
  EMPLOYER_EDIT = {:id => "pg-edit", :title => "Edit profile", :intended_for => :employer}
  EMPLOYER_FAQ = {:id => "pg-faq", :title => "Employer FAQ", :intended_for => :employer }  
  EMPLOYER_ABOUT = {:id => "pg-about", :title => "About our services for employers", :intended_for => :employer } 
  EMPLOYER_SEARCH = {:id => "pg-search", :title => "Search candidates", :intended_for => :employer}  
  EMPLOYER_INVITE_AMBASSADOR = {:id => "pg-invite-ambassador", :title => "Invite team members", :intended_for => :employer} 
  EMPLOYER_EMBED_WE_ARE_HIRING_WIDGET = {:id => "pg-embed-we-are-hiring-widget", :title => "Configure the \u201dWork With Us\u201d job posting to display on your site", :intended_for => :employer} 
  EMPLOYER_CONFIGURE_JOIN_US_TAB = {:id => "pg-configure-work-with-us", :title => "Configure the \u201dWork With Us\u201d widget", :intended_for => :employer} 
  
  # ambassadors
  TEAM_MEMBER_SIGNIN_TXT ="Team member signin" # Same text works for both cases
  AMBASSADOR_CREATE = {:id => "pg-ambassador-create", :title => Constants::AMBASSADOR_TAGLINE, :intended_for => :ambassador} 
  AMBASSADOR_SIGNIN = {:id => "pg-ambassador-signin", :title => "Team member sign-in", :intended_for => :ambassador} 
  AMBASSADOR_SHOW = {:id => "pg-ambassador_show", :title => "Dashboard", :intended_for => :ambassador} 
  AMBASSADOR_FOLLOWUP = {:id => "pg-ambassador_followup", :title => "Talk to potential candidates", :intended_for => :ambassador}   
  
  # anybody
  INDEX = {:id => "pg_index", :title => "Welcome", :intended_for => :all} 
  WE_ARE_HIRING_WIDGET = {:id => "pg-we-are-hiring-widget", :title => "\u201dCome Work With Us\u201d", :intended_for => :all} 
end
