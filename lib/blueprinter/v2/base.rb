# frozen_string_literal: true

module Blueprinter
  module V2
    # Base class for V2 Blueprints
    class Base
      extend DSL
      extend Reflection

      class << self
        # Options set on this Blueprint
        attr_accessor :options
        # Extensions set on this Blueprint
        attr_accessor :extensions
        # The name of this view, e.g. :default, :"foo.bar"
        attr_accessor :view_name
        # @api private The fully-qualified name, e.g. "MyBlueprint", or "MyBlueprint.foo.bar"
        attr_accessor :blueprint_name
        # @api private
        attr_accessor :views, :schema, :excludes, :partials, :used_partials, :eval_mutex
      end

      self.views = ViewBuilder.new(self)
      self.schema = {}
      self.excludes = []
      self.partials = {}
      self.used_partials = []
      self.extensions = []
      self.options = {}
      self.blueprint_name = name
      self.view_name = :default
      self.eval_mutex = Mutex.new

      # Initialize subclass
      def self.inherited(subclass)
        subclass.views = ViewBuilder.new(subclass)
        subclass.schema = schema.transform_values(&:dup)
        subclass.excludes = []
        subclass.partials = partials.dup
        subclass.used_partials = []
        subclass.extensions = extensions.dup
        subclass.options = options.dup
        subclass.blueprint_name = subclass.name || blueprint_name
        subclass.view_name = :default
        subclass.eval_mutex = Mutex.new
      end

      # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
      def self.inspect
        blueprint_name
      end

      # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
      def self.to_s
        blueprint_name
      end

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
        if array_like? obj
          render_collection(obj, options)
        else
          render_object(obj, options)
        end
      end

      def self.render_object(obj, options = {})
        # TODO call external renderer
      end

      def self.render_collection(objs, options = {})
        # TODO call external renderer
      end

      # Apply partials and field exclusions
      # @api private
      def self.eval!(lock = true)
        return if @evaled

        if lock
          eval_mutex.synchronize { run_eval! unless @evaled }
        else
          run_eval!
        end
      end

      # @api private
      def self.run_eval!
        used_partials.each do |name|
          if !(p = partials[name])
            raise Errors::UnknownPartial, "Partial '#{name}' could not be found in Blueprint '#{self}'"
          end
          class_eval(&p)
        end

        excludes.each { |f| schema.delete f }
        @evaled = true
      end

      # @api private
      def self.array_like?(obj)
        # TODO
      end
    end
  end
end
