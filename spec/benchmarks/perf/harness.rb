# frozen_string_literal: true

module PerfBench
  # One way of rendering a scenario's input. `render` takes the input and returns the output. `prepare`, when given,
  # takes the input and returns a zero-argument job; the harness calls `prepare` outside the timed region and times
  # only the job (lifecycle scenarios use it to define fresh blueprint classes before each timed first render).
  #
  # A scenario can carry more than one engine (several ways of rendering the same input to the same output); the
  # results and tables are keyed by engine name.
  Engine = Struct.new(:name, :render, :prepare, keyword_init: true) do
    def job(input)
      prepare ? prepare.call(input) : -> { render.call(input) }
    end
  end

  ENGINE = 'Blueprinter'

  # A scenario is built lazily so that global configuration is reset and applied before its blueprints exist.
  #
  # The build block returns a Setup.
  Scenario = Struct.new(:sweep, :label, :config, :build, :fresh_input, :note, keyword_init: true)

  # input: a zero-argument callable returning the object to render. Called once per job when `fresh_input` is set
  # (ActiveRecord, so attribute casting isn't cached across samples), otherwise once per scenario.
  Setup = Struct.new(:input, :engines, keyword_init: true)

  # A named one-factor sweep (or the realistic profiles), holding its scenarios in axis order.
  class Sweep
    attr_reader :name, :title, :description, :scenarios, :skipped
    attr_accessor :custom

    def initialize(name, title, description)
      @name = name
      @title = title
      @description = description
      @scenarios = []
      @skipped = []
    end

    # @param label [String] the axis value
    # @param fresh_input [true | false] rebuild the input for every job
    # @param config [Proc] receives Blueprinter.configuration after reset, before the blueprints are built
    # @param note [String] shown under the table
    # @param requires [Array<Symbol>] features the scenario needs (see PerfBench::FEATURES); when one is missing the
    #   scenario is recorded in `skipped` with the reason instead of being run
    def scenario(label, fresh_input: false, config: nil, note: nil, requires: [], &build)
      missing = requires.reject { |feature| PerfBench.feature?(feature) }
      if missing.empty?
        @scenarios << Scenario.new(sweep: self, label: label.to_s, config:, build:, fresh_input:, note:)
      else
        @skipped << { label: label.to_s, reason: missing.map { |f| FEATURES.fetch(f) }.join('; ') }
      end
    end

    def engine(name = ENGINE, prepare: nil, &render) = PerfBench.engine(name, prepare:, &render)

    # A sweep that measures something other than per-render cost (concurrency) supplies its own runner.
    def run_with(&block)
      self.custom = block
    end
  end

  # Optional gems, probed once at load. The value is the reason given when a scenario is skipped without it.
  FEATURES = { multi_json: 'the multi_json gem is not installed' }.freeze

  class << self
    def sweeps = @_sweeps ||= {}

    # Marks a gem as loadable (or not). Called by run.rb after its begin/rescue LoadError requires.
    def provide(feature, available)
      available_features[feature] = available
    end

    def available_features = @_available_features ||= {}

    def feature?(feature) = available_features.fetch(feature, false)

    def sweep(name, title, description, &)
      sweep = Sweep.new(name, title, description)
      sweep.instance_eval(&)
      sweeps[name] = sweep
    end

    def engine(name = ENGINE, prepare: nil, &render)
      Engine.new(name:, render:, prepare:)
    end

    def sizes
      @_sizes ||= ENV.fetch('SIZES', Runner.quick? ? 'object,1,100' : '').split(',')
                     .map { |s| s.strip == 'object' ? :object : Integer(s) }
    end

    # Sizes for the collection-size sweep: SIZES= overrides the default list.
    def size_axis(default)
      sizes.empty? ? default : sizes
    end
  end
end
