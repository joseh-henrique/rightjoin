# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
FiveYearItch::Application.initialize!

require 'monkeys/hash'
require 'monkeys/string'
require 'monkeys/active_record'