source 'http://rubygems.org'
ruby '1.9.2'

gem 'rails', '3.2.11'
gem 'pg' 
gem 'will_paginate'
gem 'memcachier'
gem 'dalli'
gem 'htmlentities', :require => false
gem 'rinku', :require => false
gem 'geoip', '~> 1.2.1'
gem 'omniauth'
gem 'omniauth-twitter'
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
gem 'omniauth-linkedin-oauth2'
 
group :development do
  gem 'rspec-rails', '2.6.1'
  #The next few lines support debugger with Ruby 1.9.3. Tested in Linux 
  gem 'linecache19', :git => 'git://github.com/mark-moseley/linecache'
  gem 'ruby-debug-base19x', '~> 0.11.30.pre4'
  gem 'ruby-debug19'

end

group :test do
  gem 'rspec-rails', '2.6.1'
  gem 'webrat', '0.7.1'
  gem 'factory_girl_rails', '1.0'
end

group :production, :staging do
  gem 'newrelic_rpm'
end

group :assets do
  gem 'jquery-rails'
  gem 'sass-rails',   '>= 3.1.4'
  #gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
end

gem 'carrierwave'
gem 'cloudinary', '~> 1.0.70'
 
# To use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
#gem 'ruby-debug19', :require => 'ruby-debug'

