gem 'minitest', '~> 5.10'
require 'minitest/autorun'
require 'blueprinter'
require 'factory_girl'

#require "rails/test_help"

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new
