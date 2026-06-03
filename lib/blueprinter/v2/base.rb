# frozen_string_literal: true

require 'blueprinter/v2/evaluator'
require 'blueprinter/v2/instance_cache'
require 'blueprinter/v2/render'

module Blueprinter
  module V2
    # Base class for V2 Blueprints
    class Base
      extend DSL
      extend Reflection

      class << self
        # @return [Symbol] The name of this view (`:default`, `:foo`)
        attr_accessor :view_name
        # @return [Symbol] The full name of this view, including any parent views (`:default`, `:foo`, `:foo.bar`)
        attr_accessor :view_path
        # @return [String] The fully-qualified name (`MyBlueprint`, `MyBlueprint.foo.bar`)
        attr_accessor :blueprint_name
        # @!visibility private
        attr_accessor :nodes
        # @!visibility private
        attr_reader :views, :schema, :formatters, :options, :extensions

        # Initialize subclass
        def inherited(subclass)
          subclass.nodes = []
          subclass.views = ViewBuilder.new(subclass)
          subclass.blueprint_name = subclass.name || blueprint_name
          subclass.view_path = :default
          subclass.view_name = :default
          subclass.eval_mutex = Mutex.new
        end

        def serializer
          eval! unless @serializer
          @serializer
        end

        # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
        def inspect = blueprint_name

        # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
        def to_s = blueprint_name

        #
        # Access a child view.
        #
        #   MyBlueprint[:extended]
        #   MyBlueprint["extended.plus"] or MyBlueprint[:extended][:plus]
        #
        # @param name [Symbol|String] Name of the view, e.g. :extended, "extended.plus"
        # @return [Class] A descendent of Blueprinter::V2::Base
        #
        def [](name)
          eval! unless @serializer
          child, children = name.to_s.split('.', 2)
          view = views[child.to_sym] || raise(Errors::UnknownView, "View '#{child}' not found in Blueprint '#{self}'")
          children ? view[children] : view
        end

        def render(obj, options = {})
          if obj.is_a?(Enumerable) && !obj.is_a?(Hash)
            render_collection(obj, options)
          else
            render_object(obj, options)
          end
        end

        def render_object(obj, options = {})
          instances = InstanceCache.new
          Render.new(obj, options, blueprint: self, instances:, collection: false)
        end

        def render_collection(objs, options = {})
          instances = InstanceCache.new
          Render.new(objs, options, blueprint: self, instances:, collection: true)
        end

        def render_as_hash(obj, options = {})
          render(obj, options).to_hash
        end

        def render_as_json(obj, options = {})
          render(obj, options).to_hash.as_json
        end

        # Apply partials and field exclusions
        # @api private
        def eval!(lock: true)
          return if @serializer || self == V2::Base

          if lock
            eval_mutex.synchronize { run_eval! unless @serializer }
          else
            run_eval!
          end
        end

        protected

        # @!visibility private
        attr_writer :views, :eval_mutex

        private

        attr_reader :eval_mutex
        attr_writer :options, :extensions, :schema, :formatters

        def run_eval!
          superclass.eval!
          eval = Evaluator.new(self)
          self.nodes = eval.nodes
          self.options = eval.options.freeze
          self.extensions = eval.extensions.freeze
          self.formatters = eval.formatters.freeze
          self.schema = eval.fields.freeze
          @serializer = Serializer.new(self)
        end
      end

      self.views = ViewBuilder.new(self)
      self.nodes = [].freeze
      self.extensions = [].freeze
      self.options = {}.freeze
      self.blueprint_name = name
      self.view_path = :default
      self.view_name = :default
      self.eval_mutex = Mutex.new

      # @return [Hash] Copy of options set on the class. Frozen after `around_blueprint_init` hooks run.
      attr_reader :options

      # @!visibility private
      def initialize
        @options = self.class.options.dup
      end

      # A descriptive name for the Blueprint view, e.g. "#<WidgetBlueprint.extended>"
      def inspect = self.class.to_s

      # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
      def to_s = self.class.to_s
    end
  end
end
