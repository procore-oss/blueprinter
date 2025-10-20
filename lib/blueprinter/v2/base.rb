# frozen_string_literal: true

require 'blueprinter/v2/instance_cache'
require 'blueprinter/v2/render'

module Blueprinter
  module V2
    # Base class for V2 Blueprints
    class Base
      extend DSL
      extend Reflection
      include Helpers

      class << self
        # @return [Hash] Options set on this Blueprint
        attr_accessor :options
        # @return [Array<Blueprinter::Extension>] Extensions set on this Blueprint
        attr_accessor :extensions
        # @return [Symbol] The name of this view, e.g. :default, :"foo.bar"
        attr_accessor :view_name
        # @return [String] The fully-qualified name, e.g. "MyBlueprint", or "MyBlueprint.foo.bar"
        attr_accessor :blueprint_name
        # @api private
        attr_accessor :views, :schema, :excludes, :formatters, :partials, :appended_partials, :eval_mutex
      end

      self.views = ViewBuilder.new(self)
      self.schema = {}
      self.excludes = []
      self.formatters = {}
      self.partials = {}
      self.appended_partials = []
      self.extensions = []
      self.options = {}
      self.blueprint_name = name
      self.view_name = :default
      self.eval_mutex = Mutex.new

      # Initialize subclass
      def self.inherited(subclass)
        subclass.views = views.dup_for(subclass)
        subclass.schema = schema.transform_values(&:dup)
        subclass.excludes = []
        subclass.formatters = formatters.dup
        subclass.partials = partials.dup
        subclass.appended_partials = []
        subclass.extensions = extensions.dup
        subclass.options = options.dup
        subclass.blueprint_name = subclass.name || blueprint_name
        subclass.view_name = :default
        subclass.eval_mutex = Mutex.new
      end

      # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
      def self.inspect = blueprint_name

      # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
      def self.to_s = blueprint_name

      # Set the view name
      # @api private
      def self.append_name(name)
        self.blueprint_name = "#{blueprint_name}.#{name}"
        self.view_name = blueprint_name.sub(/^[^.]+\./, '').to_sym
      end

      #
      # Access a child view.
      #
      #   MyBlueprint[:extended]
      #   MyBlueprint["extended.plus"] or MyBlueprint[:extended][:plus]
      #
      # @param name [Symbol|String] Name of the view, e.g. :extended, "extended.plus"
      # @return [Class] A descendent of Blueprinter::V2::Base
      #
      def self.[](name)
        eval! unless @evaled
        child, children = name.to_s.split('.', 2)
        view = views[child.to_sym] || raise(Errors::UnknownView, "View '#{child}' could not be found in Blueprint '#{self}'")
        children ? view[children] : view
      end

      def self.render(obj, options = {})
        if obj.is_a?(Enumerable) && !obj.is_a?(Hash)
          render_collection(obj, options)
        else
          render_object(obj, options)
        end
      end

      def self.render_object(obj, options = {})
        instances = InstanceCache.new
        blueprint = get_blueprint_class(instances, options)
        Render.new(obj, options, blueprint:, instances:, collection: false)
      end

      def self.render_collection(objs, options = {})
        instances = InstanceCache.new
        blueprint = get_blueprint_class(instances, options)
        Render.new(objs, options, blueprint:, instances:, collection: true)
      end

      # @api private
      def self.get_blueprint_class(instances, options)
        hooks = Hooks.new(extensions.map { |ext| instances.extension ext })
        if hooks.registered? :blueprint
          ctx = Context::Render.new(instances.blueprint(self), [], options, 1)
          hooks.last(:blueprint, ctx) || self
        else
          self
        end
      end

      # Apply partials and field exclusions
      # @api private
      def self.eval!(lock: true)
        return if @evaled

        if lock
          eval_mutex.synchronize { run_eval! unless @evaled }
        else
          run_eval!
        end
      end

      # @api private
      def self.run_eval!
        appended_partials.each(&method(:apply_partial!))
        excludes.each { |f| schema.delete f }
        extensions.freeze
        options.freeze
        formatters.freeze
        schema.freeze
        schema.each_value do |f|
          f.options&.freeze
          f.freeze
        end
        @evaled = true
      end

      # @api private
      def self.apply_partial!(name)
        p = partials[name] || raise(Errors::UnknownPartial, "Partial '#{name}' could not be found in Blueprint '#{self}'")
        class_eval(&p)
      end

      # A descriptive name for the Blueprint view, e.g. "#<WidgetBlueprint.extended>"
      def inspect = self.class.to_s

      # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
      def to_s = self.class.to_s
    end
  end
end
