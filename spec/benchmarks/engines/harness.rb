# frozen_string_literal: true

module EngineBench
  # One way of rendering a scenario's input: V1, V2, or V2 with the Legacy* extensions.
  #
  # `render` takes the input and returns the output. `prepare`, when given, takes the input and returns a zero-argument
  # job; the harness calls `prepare` outside the timed region and times only the job (lifecycle scenarios use it to
  # define fresh blueprint classes before each timed first render).
  Engine = Struct.new(:name, :render, :prepare, keyword_init: true) do
    def job(input)
      prepare ? prepare.call(input) : -> { render.call(input) }
    end
  end

  # A scenario is built lazily so that V1 global configuration is reset and applied before its blueprints exist.
  #
  # The build block returns a Setup.
  Scenario = Struct.new(:sweep, :label, :v1_config, :build, :fresh_input, :note, keyword_init: true)

  # input: a zero-argument callable returning the object to render. Called once per job when `fresh_input` is set
  # (ActiveRecord, so attribute casting isn't cached across samples), otherwise once per scenario.
  #
  # `engines` may contain nils (a builder returns nil for an engine that isn't available); they are dropped.
  Setup = Struct.new(:input, :engines, keyword_init: true) do
    def initialize(input:, engines:)
      super(input:, engines: engines.compact)
    end
  end

  # A named one-factor sweep (or the realistic profiles), holding its scenarios in axis order.
  class Sweep
    attr_reader :name, :title, :description, :scenarios, :skipped, :engine_names
    attr_accessor :custom

    def initialize(name, title, description, engines)
      @name = name
      @title = title
      @description = description
      @engine_names = engines.select { |e| EngineBench.engine_available?(e) }
      @scenarios = []
      @skipped = []
    end

    # @param label [String] the axis value
    # @param fresh_input [true | false] rebuild the input for every job
    # @param v1_config [Proc] receives Blueprinter.configuration after reset, before the blueprints are built
    # @param note [String] shown under the table
    # @param requires [Array<Symbol>] features the scenario needs (see EngineBench::FEATURES); when one is missing the
    #   scenario is recorded in `skipped` with the reason instead of being run
    def scenario(label, fresh_input: false, v1_config: nil, note: nil, requires: [], &build)
      missing = requires.reject { |feature| EngineBench.feature?(feature) }
      if missing.empty?
        @scenarios << Scenario.new(sweep: self, label: label.to_s, v1_config:, build:, fresh_input:, note:)
      else
        @skipped << { label: label.to_s, reason: missing.map { |f| FEATURES.fetch(f) }.join('; ') }
      end
    end

    def engine(name, prepare: nil, &render) = EngineBench.engine(name, prepare:, &render)

    # A sweep that measures something other than per-render cost (concurrency) supplies its own runner.
    def run_with(&block)
      self.custom = block
    end
  end

  STANDARD_ENGINES = %w[V1 V2].freeze
  LEGACY_ENGINES = ['V1', 'V2', 'V2+Legacy'].freeze

  # Optional capabilities, probed once at load. The value is the reason given when a scenario is skipped without it.
  FEATURES = {
    v2: 'Blueprinter::V2 is not defined in this version of the gem',
    multi_json: 'the multi_json gem is not installed',
    opentelemetry: 'the opentelemetry-api gem is not installed'
  }.freeze

  class << self
    def sweeps = @_sweeps ||= {}

    # Marks a gem as loadable (or not). Called by run.rb after its begin/rescue LoadError requires.
    def provide(feature, available)
      available_features[feature] = available
    end

    def available_features
      @_available_features ||= { v2: defined?(Blueprinter::V2) ? true : false }
    end

    def feature?(feature) = available_features.fetch(feature) { false }

    def v2? = feature?(:v2)

    # V2 and V2+Legacy exist only when the V2 engine does; V1 always does.
    def engine_available?(name) = name == 'V1' || v2?

    def sweep(name, title, description, engines: STANDARD_ENGINES, &block)
      sweep = Sweep.new(name, title, description, engines)
      sweep.instance_eval(&block)
      sweeps[name] = sweep
    end

    # @return [Engine, nil] nil when the engine isn't available, so callers can build engine lists with `compact`
    def engine(name, prepare: nil, &render)
      Engine.new(name:, render:, prepare:) if engine_available?(name)
    end

    # Render with V2 using the public entry point. `render` treats any non-Hash Enumerable as a collection, including a
    # single Struct, so a single Struct goes through `render_object` instead.
    def v2_hash(blueprint, input, options = {})
      if input.is_a?(Struct)
        blueprint.render_object(input, options).to_hash
      else
        blueprint.render(input, options).to_hash
      end
    end

    def v2_json(blueprint, input, options = {})
      if input.is_a?(Struct)
        blueprint.render_object(input, options).to_json
      else
        blueprint.render(input, options).to_json
      end
    end

    def sizes
      @_sizes ||= ENV.fetch('SIZES', '').split(',').map { |s| s.strip == 'object' ? :object : Integer(s) }
    end

    # Sizes for the collection-size sweep: SIZES= overrides the default list.
    def size_axis(default)
      sizes.empty? ? default : sizes
    end
  end
end
