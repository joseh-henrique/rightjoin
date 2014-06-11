# Be sure to restart your server when you modify this file.

if Rails.env.production?
  FiveYearItch::Application.config.session_store :cookie_store, key: '_fyi_session', :domain => ".#{Constants::SITENAME_LC}"
elsif Rails.env.staging?
  FiveYearItch::Application.config.session_store :cookie_store, key: '_fyi_session', :domain => ".fyistage.herokuapp.com"
else
  FiveYearItch::Application.config.session_store :cookie_store, key: '_fyi_session', :domain => :all
end

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# FiveYearItch::Application.config.session_store :active_record_store
