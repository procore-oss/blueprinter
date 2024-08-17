# frozen_string_literal: true

require 'blueprinter/v2/dsl'
require 'blueprinter/v2/options'
require 'blueprinter/v2/reflection'

module Blueprinter
  # Base class for V2 Blueprints
  class V2
    extend DSL
    extend Reflection

    class << self
      attr_accessor :views, :fields, :extensions, :options
      # The fully-qualified name, e.g. "MyBlueprint", or "MyBlueprint.foo.bar"
      attr_accessor :blueprint_name
    end

    self.views = {}
    self.fields = {}
    self.extensions = []
    self.options = Options.new(DEFAULT_OPTIONS)
    self.blueprint_name = name

    # Initialize subclass
    def self.inherited(subclass)
      subclass.views = { default: subclass }
      subclass.fields = fields.transform_values(&:dup)
      subclass.extensions = extensions.dup
      subclass.options = options.dup
      subclass.blueprint_name = subclass.name || blueprint_name
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
      view.to_s.split('.').reduce(self) do |blueprint, child|
        blueprint.views[child.to_sym] ||
          raise(Errors::UnknownView, "View '#{child}' could not be found in Blueprint '#{blueprint}'")
      end
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
