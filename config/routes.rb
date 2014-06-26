FiveYearItch::Application.routes.draw do
  match '/mailto', :to => redirect('/mailto.html')
  
  # admin
  match 'admin/update_engineers', :to => 'admin#send_jobs_update_to_engineers'
  match 'admin/update_employers', :to => 'admin#send_jobs_update_to_employers'
  match 'admin/welcome_employers', :to => 'admin#send_welcome_email_to_employers'
  match 'admin/welcome_engineers', :to => 'admin#send_welcome_email_to_engineers'
  match 'admin/update_employers_about_new_contacts', :to => 'admin#send_update_employers_about_new_contacts'
 
  match 'admin/update_admin', :to => 'admin#send_update_to_admin'
  match 'admin/events', :to => 'admin#events'
  match 'admin/invites_to_approve', :to => 'admin#invites_to_approve'
  match 'admin/candidate/:id/inactivate', :to => 'admin#inactivate_candidate', :as => :admin_inactivate_candidate
  match 'admin/candidate/:id/recommend', :to => 'admin#recommend_candidate_to_job', :as => :admin_recommend_candidate_to_job  
  match 'admin/invite/:id/approve', :to => 'admin#approve_invite', :as => :admin_approve_invite
  match 'admin/locations/:locale', :to => 'admin#locations', :as => :admin_locations
  match 'admin/location', :to => 'admin#manage_location', :as => :admin_manage_location, :via => :post
  match 'admin/positions', :to => 'admin#positions', :as => :admin_positions
  match 'admin/position', :to => 'admin#attach_position', :as => :admin_attach_position, :via => :post
  match 'admin/job/:id/recommend', :to => 'admin#recommend_candidates', :as => :admin_recommend_candidates
  match 'admin/job/:id/close', :to => 'admin#close_job', :as => :admin_close_job
  match 'admin/skills', :to => 'admin#skills', :as => :admin_skills
  match 'admin/skill', :to => 'admin#approve_skill', :as => :admin_approve_skill, :via => :post  
  match 'admin/import_jobs', :to => 'admin#import_jobs', :as => :admin_import_jobs, :via => :post  
  match 'admin/report_statistics', :to => 'admin#report_statistics'
  match 'admin/', :to => 'admin#console'  
  
  # shares
  match 'shares/increment', :to => 'shares#increment_counter', :as => :shares_increment_counter, :via => :post 
  
  #ominauth
  match "/auth/:provider/callback" => "omniauth#callback"
  match "/login_with/:provider" => "omniauth#login_with", :as => :ominauth_login_with, :via => :post 
  
  # use employer's refnum
  match "/team/:refnum/signin" => "ambassadors#signin", :as => :ambassadors_signin
  # use ambassador's refnum
  match "/team/:refnum/img(/:timestamp)" => "ambassadors#serve_avatar", :as => :ambassador_avatar
  # use infointerview's refnum
  match "/lead/:refnum/img(/:timestamp)" => "infointerviews#serve_avatar", :as => :lead_avatar
  
  # infointerview
  match "/lead/:employer_id/create" => "infointerviews#create", :via => :post, :as => :infointerview_create
  match "/infointerview/:id/close" => "infointerviews#close", :via => :post, :as => :infointerview_close
  match "/infointerview/:id/reopen" => "infointerviews#reopen", :via => :post, :as => :infointerview_reopen
  match "/infointerview/:id/delegate" => "infointerviews#delegate", :via => :post, :as => :infointerview_delegate
  
  # "work with us" widget
  match '/:refnum/join', :to => 'employers#we_are_hiring', :via => :get, :as => :we_are_hiring_employer, :defaults => { :locale => nil }
  match '/:refnum/ping', :to => 'employers#ping', :via => :get, :as => :ping_employer, :defaults => { :locale => nil }
  
  resources :photos, :only => [:index, :create] 
   
  scope "(:locale)", :locale => /us|uk|au|ca|il|in|/ do
    root :to => 'pages#index'
    match '/', :to => 'pages#index', :as => :country_root
    
    # employee
    match '/welcome', :to => 'pages#welcome'
    match '/register', :to => 'pages#register'  
    match '/jobs', :to => 'pages#jobs'
    match '/privacy', :to => 'pages#privacy'
    match '/faq', :to => 'pages#faq'
    match '/engineers', :to => 'pages#engineers'
    match '/signin', :to => 'sessions#employee_signin', :as => :employee_signin
    match '/signout', :to => 'sessions#employee_signout', :as => :employee_signout  
    
    # employer
    match '/employer/welcome', :to => 'pages#employer_welcome'
    match '/employer/get_started', :to => 'pages#employer_get_started'
    match '/employer/privacy', :to => 'pages#employer_privacy'
    match '/employer/faq', :to => 'pages#employer_faq'    
    match '/employer/search', :to => 'pages#employer_search'
    match '/employer/signin', :to => 'sessions#employer_signin', :as => :employer_signin
    match '/employer/signout', :to => 'sessions#employer_signout', :as => :employer_signout
    match '/employer/:refnum/work_with_us_tab', :to => 'employers#work_with_us_tab', :via => :get, :as => :work_with_us_tab_employer
    match '/employer/:refnum/work_with_us_test', :to => 'employers#work_with_us_test', :via => :get, :as => :work_with_us_test_employer

    resources :company_ratings, only: [:create]
     
    resources :users, only: [:create, :edit, :update, :show, :index] do
      member do
        post 'verify'
        post 'set_status'
        post 'change_pw'
        post 'unsubscribe'
        get  'unsubscribe'
      end
      collection do
        post 'forgot_pw'   
      end
    end
    
    resources :employers, only: [:create, :edit, :update, :show] do
      member do
        post 'verify'
        post 'change_pw'
        post 'unsubscribe'
        get  'unsubscribe'
        get  'configure_join_us_tab'
      end
      
      collection do
        post 'forgot_pw'
      end
      
      resources :jobs, only: [:new, :create, :edit, :update, :destroy] do 
        collection do
          post 'copy_properties'   
        end
       	member do
          get 'recommended'
          get 'leads'
          post 'leads_set_seen'
        end
      end
      
      resources :ambassadors, only: [:show, :new, :create, :edit, :update, :destroy] do
        member do
          post 'share'
          post 'close_followup'
          get 'followup'
        end
      end
    end
    
    match '/jobs/search' , :to => 'jobs#search',  :via => :get, :as => :search_jobs
  
    #tags
    match 'autocomplete/locations' => 'autocomplete#locations',  :via => :get
    match 'autocomplete/skills' => 'autocomplete#skills',  :via => :get
    match 'autocomplete/positions' => 'autocomplete#positions',  :via => :get
    match 'autocomplete/jobqualifiers' => 'autocomplete#jobqualifiers',  :via => :get
    
    #interviews
    resources :interviews, only: [:create, :destroy]
    
    # employer fallback, must be last
    match '/employers', :to => 'pages#employer_welcome'
    match '/employer', :to => 'pages#employer_welcome'
  end
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'  
end
