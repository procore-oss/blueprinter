# frozen_string_literal: true

require_relative 'fixtures'

module EngineBench
  # Builders for the baseline shape (widget, company, parts) in each engine. Each call defines fresh classes, so a
  # scenario's V1 configuration applies and no compiled state carries over between scenarios. Sweeps pass a block to
  # add scenario-specific DSL calls to the widget's class body.
  module Blueprints
    module V1
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
      def widget(width: 20, company: V1.company, part: V1.part, fields: true, &extra)
        names = Fixtures.field_names(width)
        Class.new(Blueprinter::Base) do
          identifier :id
          fields(*names) if fields
          association :company, blueprint: company if company
          association :parts, blueprint: part if part
          class_eval(&extra) if extra
        end
      end
    end

    # Every builder returns nil when `Blueprinter::V2` isn't defined; the engine helpers then drop the V2 engines.
    module V2
      module_function

      def app(&extra)
        return unless EngineBench.v2?

        Class.new(Blueprinter::V2::Base) do
          self.blueprint_name = 'ApplicationBlueprint'
          class_eval(&extra) if extra
        end
      end

      def company(app = V2.app, &extra)
        return unless EngineBench.v2?

        Class.new(app) do
          self.blueprint_name = 'CompanyBlueprint'
          fields :id, :name, :city
          class_eval(&extra) if extra
        end
      end

      def part(app = V2.app, &extra)
        return unless EngineBench.v2?

        Class.new(app) do
          self.blueprint_name = 'PartBlueprint'
          fields :id, :name, :number
          class_eval(&extra) if extra
        end
      end

      def widget(app = V2.app, width: 20, company: V2.company(app), part: V2.part(app), fields: true, &extra)
        return unless EngineBench.v2?

        names = Fixtures.field_names(width)
        Class.new(app) do
          self.blueprint_name = 'WidgetBlueprint'
          field :id
          fields(*names) if fields
          association :company, company if company
          association :parts, [part] if part
          class_eval(&extra) if extra
        end
      end
    end

    # Reads a field with `public_send`, as V1's default extractor does for non-Hash objects.
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

    # V1's only hook. Returns the object unchanged.
    class NoopPreRender < Blueprinter::Extension
      def pre_render(object, _blueprint, _view, _options) = object
    end

    # Registers one pass-through method for every V2 hook except `around_hook`, or only the non-field ones.
    class NoopHooks < Blueprinter::Extension
      OBJECT_HOOKS = %i[around_result around_blueprint_init around_serialize_object around_serialize_collection
                        around_blueprint].freeze
      FIELD_HOOKS = %i[around_field_value around_object_value around_collection_value].freeze

      def initialize(hooks = OBJECT_HOOKS + FIELD_HOOKS)
        hooks.each { |hook| send(hook, :pass) }
      end

      def pass(ctx) = yield(ctx)
    end

    # The V2 equivalent of KindTransformer, as an `around_blueprint` hook.
    class KindExtension < Blueprinter::Extension
      def initialize = around_blueprint :add_kind

      def add_kind(ctx)
        result = yield ctx
        result[:kind] = 'record'
        result
      end
    end

    # A tracing-style `around_hook`: counts and times every extension hook call into the render's store.
    class HookTimer < Blueprinter::Extension
      def initialize = around_hook :time_hook

      def time_hook(ctx)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        yield
        stats = (ctx.store[:hook_timer] ||= [0, 0.0])
        stats[0] += 1
        stats[1] += Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      end
    end

    # Serializes JSON with Oj, for comparison with V1's `config.generator = Oj`.
    class OjResult < Blueprinter::Extension
      def initialize = around_result :dump

      def dump(ctx)
        result = yield ctx
        ctx.format == :json ? serialized(::Oj.generate(result)) : result
      end
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
      v1 = Blueprints::V1.widget(width:)
      v2 = Blueprints::V2.widget(width:)
      json ? json_engines(v1, v2) : hash_engines(v1, v2)
    end

    # V1 and V2 engines rendering to a Hash. `legacy`, when given, is a V2 blueprint using the Legacy* extensions.
    def hash_engines(v1, v2, legacy = nil, options: {}, legacy_options: options)
      [
        v1 && engine('V1') { |input| v1.render_as_hash(input, options) },
        v2 && engine('V2') { |input| v2_hash(v2, input, options) },
        legacy && engine('V2+Legacy') { |input| v2_hash(legacy, input, legacy_options) }
      ].compact
    end

    def json_engines(v1, v2, legacy = nil, options: {}, legacy_options: options)
      [
        v1 && engine('V1') { |input| v1.render(input, options) },
        v2 && engine('V2') { |input| v2_json(v2, input, options) },
        legacy && engine('V2+Legacy') { |input| v2_json(legacy, input, legacy_options) }
      ].compact
    end
  end
end
