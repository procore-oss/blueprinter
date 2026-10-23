# frozen_string_literal: true

require 'blueprinter/field'
require 'blueprinter/extractors/auto_extractor'

class MockField
  attr_reader :name, :method

  def initialize(method, name = nil)
    @method = method
    @name = name || method
  end

  # ViewCollection compiles every field while building its cache. Delegate so a change to
  # Field#compile is what these specs run, instead of a second copy of the fast path.
  def compile
    Blueprinter::Field.new(
      @method,
      @name,
      Blueprinter::AutoExtractor.new,
      Blueprinter::Base,
      {}
    ).compile
  end
end
