# frozen_string_literal: true

require 'blueprinter/v2/dsl'
require 'blueprinter/v2/options'
require 'blueprinter/v2/reflection'
require 'blueprinter/v2/view_builder'

module Blueprinter
  # Base class for V2 Blueprints
  class V2
    extend DSL
    extend Reflection

    class << self
      # Options set on this Blueprint
      attr_accessor :options
      # Extensions set on this Blueprint
      attr_accessor :extensions
      # @api private The fully-qualified name, e.g. "MyBlueprint", or "MyBlueprint.foo.bar"
      attr_accessor :blueprint_name
      # @api private
      attr_accessor :views, :fields, :excludes, :partials, :used_partials, :eval_mutex
    end

    self.views = ViewBuilder.new(self)
    self.fields = {}
    self.excludes = []
    self.partials = {}
    self.used_partials = []
    self.extensions = []
    self.options = Options.new(DEFAULT_OPTIONS)
    self.blueprint_name = name
    self.eval_mutex = Mutex.new

    # Initialize subclass
    def self.inherited(subclass)
      subclass.views = ViewBuilder.new(subclass)
      subclass.fields = fields.transform_values(&:dup)
      subclass.excludes = []
      subclass.partials = partials.dup
      subclass.used_partials = []
      subclass.extensions = extensions.dup
      subclass.options = options.dup
      subclass.blueprint_name = subclass.name || blueprint_name
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

    # Append the sub-view name to blueprint_name
    # @api private
    def self.append_name(name)
      self.blueprint_name = "#{blueprint_name}.#{name}"
    end

    #
    # Access a child view.
    #
    #   MyBlueprint[:extended]
    #   MyBlueprint["extended.plus"] or MyBlueprint[:extended][:plus]
    #
    # @param view [Symbol|String] Name of the view, e.g. :extended, "extended.plus"
    # @return [Class] A descendent of Blueprinter::V2
    #
    def self.[](view)
      eval! unless @evaled
      view.to_s.split('.').reduce(self) do |blueprint, child|
        blueprint.views[child.to_sym] ||
          raise(Errors::UnknownView, "View '#{child}' could not be found in Blueprint '#{blueprint}'")
      end
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

      excludes.each { |f| fields.delete f }
      @evaled = true
    end

    # Render the object
    def self.render(obj, options = {})
      new.render(obj, options)
    end

    # Render the object
    def render(obj, options = {})
      # TODO: call an external Render module/class, passing in self, obj, and options
    end
  end
end
