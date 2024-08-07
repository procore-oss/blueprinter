# frozen_string_literal: true

require 'blueprinter/v2/association'
require 'blueprinter/v2/dsl'
require 'blueprinter/v2/field'
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
      # Name of the view, e.g. :default, :foo, :"foo.bar"
      attr_accessor :view_name
    end

    self.views = {}
    self.fields = {}
    self.extensions = []
    self.options = Options.new(DEFAULT_OPTIONS)
    self.blueprint_name = name
    self.view_name = :default

    # Initialize subclass
    def self.inherited(subclass)
      subclass.views = { default: subclass }
      subclass.fields = fields.transform_values(&:dup)
      subclass.extensions = extensions.dup
      subclass.options = options.dup
      subclass.blueprint_name = subclass.name || blueprint_name
      subclass.view_name = subclass.name ? :default : view_name
    end

    # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
    def self.inspect
      blueprint_name
    end

    # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
    def self.to_s
      blueprint_name
    end

    # Append the sub-view name to blueprint_name and view_name
    def self.append_name(name)
      self.blueprint_name = "#{blueprint_name}.#{name}"
      self.view_name = view_name == :default ? name : :"#{view_name}.#{name}"
    end

    # Access a child view
    #   MyBlueprint[:extended]
    #   MyBlueprint[:extended][:plus]
    #   MyBlueprint["extended.plus"]
    def self.[](view)
      view.to_s.split('.').reduce(self) do |blueprint, child|
        blueprint.views[child.to_sym] ||
          raise(Errors::UnknownView, "View '#{child}' could not be found in Blueprint '#{blueprint}'")
      end
    end

    def self.render(obj, options = {})
      new.render(obj, options)
    end

    def render(obj, options = {})
      # TODO: call an external Render module/class, passing in self, obj, and options.
      #
      # I propose this new renderer (possibly shared with 1.x) would have an "outer" and
      # "inner" API. The "inner" API would be used when rendering nested Blueprints. The
      # "outer" API would only be called here.
      #
      # This design would allow for some render hooks to only be called ONCE per render (baring
      # a field/association block calling "render" again), and others to be called on every
      # nested Blueprint. This would fix some persistent issues with blueprinter-activerecord.
    end
  end
end
