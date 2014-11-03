if Rails.env.staging? || Rails.env.production?
  Rack::Timeout.timeout = 10  # seconds
end