# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'blueprinter'
require 'json'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |file| require file }

module SpecHelpers
  def reset_blueprinter_config!
    Blueprinter.instance_variable_set(:@configuration, nil)
  end
end

RSpec.configure do |config|
  config.include SpecHelpers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
