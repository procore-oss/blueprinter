# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'blueprinter'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |file| require file }

# BLUEPRINTER_COMPILE_VIEWS=1 runs the whole suite with compiled views enabled, including after configuration resets
if ENV['BLUEPRINTER_COMPILE_VIEWS'] == '1'
  Blueprinter::Configuration.prepend(Module.new do
    def initialize
      super
      @compile_views = true
    end
  end)
end

module SpecHelpers
  def reset_blueprinter_config!
    Blueprinter.reset_configuration!
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
