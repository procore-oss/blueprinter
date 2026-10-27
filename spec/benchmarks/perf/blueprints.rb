# frozen_string_literal: true

require_relative 'fixtures'

module PerfBench
  # Builders for the baseline shape (widget, company, parts). Each call defines fresh classes, so a scenario's
  # configuration applies and no compiled view state carries over between scenarios. Sweeps pass a block to add
  # scenario-specific DSL calls to the widget's class body.
  module Blueprints
    module_function

    def company(&extra)
      Class.new(Blueprinter::Base) do
        identifier :id
        fields :name, :city
        class_eval(&extra) if extra
      end
    end

    def part(&extra)
      Class.new(Blueprinter::Base) do
        identifier :id
        fields :name, :number
        class_eval(&extra) if extra
      end
    end

    # @param fields [Boolean] define the `width` plain fields (sweeps that define their own pass false)
    def widget(width: 20, company: Blueprints.company, part: Blueprints.part, fields: true, &extra)
      names = Fixtures.field_names(width)
      Class.new(Blueprinter::Base) do
        identifier :id
        fields(*names) if fields
        association :company, blueprint: company if company
        association :parts, blueprint: part if part
        class_eval(&extra) if extra
      end
    end

    # Reads a field with `public_send`, as the default extractor does for non-Hash objects.
    class PassThroughExtractor < Blueprinter::Extractor
      def extract(field_name, object, _local_options, _options = {})
        object.public_send(field_name)
      end
    end

    # Adds a `kind` key to the finished Hash.
    class KindTransformer < Blueprinter::Transformer
      def transform(hash, _object, _options)
        hash[:kind] = 'record'
      end
    end

    # The one extension hook. Returns the object unchanged.
    class NoopPreRender < Blueprinter::Extension
      def pre_render(object, _blueprint, _view, _options) = object
    end
  end

  # Baseline: 100 Symbol-keyed Hash widgets, each with an id, 20 plain fields (strings and integers), one company
  # (object association, 3 fields), and 3 parts (collection association, 3 fields each); default view; render to a
  # Hash; warm classes. Every sweep varies one of these from the baseline.
  BASELINE_SIZE = 100
  NAMES = Fixtures.field_names(20).freeze
  HALF = NAMES.each_slice(2).map(&:first).freeze # every other field: the ones a 50% condition skips
  EXTRA = Fixtures.field_names(30).drop(20).freeze # f20..f29, added by views
  OPTION_KEYS = Array.new(20) { |i| :"opt_#{i}" }.freeze
  TIME_FORMAT = '%Y-%m-%d %H:%M:%S'
  DATE_FORMAT = '%Y-%m-%d'
  EXTRACTOR = Blueprints::PassThroughExtractor.new

  class << self
    def baseline_engines(width: 20, json: false)
      blueprint = Blueprints.widget(width:)
      json ? json_engines(blueprint) : hash_engines(blueprint)
    end

    # @return [Array<Engine>] one engine rendering `blueprint` to a Hash
    def hash_engines(blueprint, options: {})
      [engine { |input| blueprint.render_as_hash(input, options) }]
    end

    # @return [Array<Engine>] one engine rendering `blueprint` to a JSON String
    def json_engines(blueprint, options: {})
      [engine { |input| blueprint.render(input, options) }]
    end
  end
end
