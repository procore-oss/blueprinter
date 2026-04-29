# frozen_string_literal: true

require 'blueprinter/v2/instance_cache'
require 'blueprinter/v2/render'

module Blueprinter
  module V2
    #
    # Base class for V2 Blueprints. See {Blueprinter::V2::DSL} for the full API.
    #
    # ```
    # class WidgetBlueprint < ApplicationBlueprint
    #   field :name
    #   field :description, default: "None"
    #   association :category, CategoryBlueprint
    #
    #   view :with_parts do
    #     association :parts, [PartBlueprint]
    #   end
    # end
    # ```
    #
    # Blueprints can inherit from other Blueprints, or from specific views. (Views are just anonymous subclasses.)
    #
    # ```
    # class SpecialzedWidgetBlueprint < WidgetBlueprint
    #   # ...
    # end
    #
    # class WidgetPartsBlueprint < WidgetBlueprint[:with_parts]
    #   # ...
    # end
    # ```
    #
    # It's good practice to define a base Blueprint for your applicaiton that defines common fields,
    # options, and extensions. (Note that V1's `Blueprinter.configure` block has no effect on V2 Blueprints.)
    #
    # ```
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   options[:exclude_if_nil] = true
    #   format(Time) { |t| t.iso8601 }
    #   extensions << MyExtension.new
    #
    #   fields :id, :created_at, :updated_at
    # end
    # ```
    #
    # A Blueprint class is initialized exactly once during a given render. The instance is available through the
    # context object passed to if/unless/default Procs, field definition blocks, and extension hooks. See
    # {Blueprinter::V2::Context} for more info.
    #
    class Base
      extend DSL
      extend Reflection

      class << self
        # @return [Hash] Options set on this Blueprint
        attr_accessor :options
        # @return [Array<Blueprinter::Extension>] Extensions set on this Blueprint
        attr_accessor :extensions
        # @return [Symbol] The name of this view (Example: `:default`, `:foo.bar`)
        attr_accessor :view_name
        # @return [String] The fully-qualified name (Example: `MyBlueprint`, `MyBlueprint.foo.bar`)
        attr_accessor :blueprint_name
        # @!visibility private
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
      # @!visibility private
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

      # @!visibility private
      # @return [Blueprinter::V2::Serializer]
      def self.serializer
        eval! unless @serializer
        @serializer
      end

      # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
      def self.inspect = blueprint_name

      # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
      def self.to_s = blueprint_name

      # Set the view name
      # @!visibility private
      def self.append_name(name)
        self.blueprint_name = "#{blueprint_name}.#{name}"
        self.view_name = blueprint_name.sub(/^[^.]+\./, '').to_sym
      end

      #
      # Access a child view.
      #
      #   MyBlueprint[:extended]
      #
      # Access nested views using dot syntax or nested Hash syntax.
      #
      #   MyBlueprint["extended.plus"]
      #   MyBlueprint[:extended][:plus]
      #
      # The `:default` view is an alias to the Blueprint class itself:
      #
      #   MyBluprint[:default] == MyBlueprint
      #
      # @param name [Symbol|String] Name of the view, e.g. :extended, "extended.plus"
      # @return [Class] A descendent of Blueprinter::V2::Base
      #
      def self.[](name)
        eval! unless @serializer
        child, children = name.to_s.split('.', 2)
        view = views[child.to_sym] || raise(Errors::UnknownView, "View '#{child}' could not be found in Blueprint '#{self}'")
        children ? view[children] : view
      end

      # Serialize an object or collection (Enumerable) using this Blueprint.
      #
      # Call `to_json`, `to_hash`, or `to(format)` on the return value to get the final serialized value.
      #
      #   WidgetBlueprint.render(widget).to_json
      #
      # In Rails controllers rendering JSON, `to_json` is not required, making it compatible with V1:
      #
      #   render json: WidgetBlueprint.render(widget)
      #
      # @param object [Object]
      # @param options [Hash] Options provided by any enabled extensions
      # @return [Blueprinter::V2::Render]
      def self.render(object, options = {})
        if object.is_a?(Enumerable) && !object.is_a?(Hash)
          render_collection(object, options)
        else
          render_object(object, options)
        end
      end

      # Serialize an object using this Blueprint.
      #
      # Call `to_json`, `to_hash`, or `to(format)` on the return value to get the final serialized value.
      #
      #   WidgetBlueprint.render_object(widget).to_json
      #
      # @param object [Object]
      # @param options [Hash] Options provided by any enabled extensions
      # @return [Blueprinter::V2::Render]
      def self.render_object(object, options = {})
        instances = InstanceCache.new
        Render.new(object, options, blueprint: self, instances:, collection: false)
      end

      # Serialize a collection (Enumerable) using this Blueprint.
      #
      # Call `to_json`, `to_hash`, or `to(format)` on the return value to get the final serialized value.
      #
      #   WidgetBlueprint.render_collection(Widget.all).to_json
      #
      # @param objects [Object]
      # @param options [Hash] Options provided by any enabled extensions
      # @return [Blueprinter::V2::Render]
      def self.render_collection(objects, options = {})
        instances = InstanceCache.new
        Render.new(objects, options, blueprint: self, instances:, collection: true)
      end

      # Apply partials and field exclusions
      # @!visibility private
      def self.eval!(lock: true)
        return if @serializer

        if lock
          eval_mutex.synchronize { run_eval! unless @serializer }
        else
          run_eval!
        end
      end

      # @!visibility private
      def self.run_eval!
        appended_partials.each(&method(:apply_partial!))
        excludes.each { |f| schema.delete f }
        extensions.freeze
        options.freeze
        formatters.freeze
        schema.freeze
        serializer = Serializer.new(self)
        @serializer = serializer
      end

      # @!visibility private
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
