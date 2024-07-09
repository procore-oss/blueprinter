# frozen_string_literal: true

module Blueprinter
  class V2
    class << self
      attr_accessor :views, :fields, :extensions, :blueprint_name
    end

    self.views = {}
    self.fields = {}
    self.extensions = []
    self.blueprint_name = []

    # Initialize subclass
    def self.inherited(subclass)
      subclass.views = {}
      subclass.fields = fields.dup
      subclass.extensions = extensions.dup
      subclass.blueprint_name = subclass.name ? [subclass.name] : blueprint_name.dup
    end

    # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint:extended"
    def self.inspect
      to_s
    end

    # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint:extended"
    def self.to_s
      blueprint_name.join ':'
    end

    # Access a child view
    def self.[](view)
      views.fetch(view)
    rescue KeyError
      raise Blueprinter::Errors::UnknownView, "View '#{view}' could not be found in Blueprint '#{self}'"
    end

    # Define a new child view, which is a subclass of self
    def self.view(name, &definition)
      views[name] = Class.new(self)
      views[name].blueprint_name << name
      views[name].class_eval(&definition) if definition
      views[name]
    end

    # Define a field
    # rubocop:todo Lint/UnusedMethodArgument
    def self.field(name, options = {})
      fields[name] = 'TODO'
    end

    # Define an association
    def self.association(name, blueprint, options = {})
      fields[name] = 'TODO'
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

    # rubocop:enable Lint/UnusedMethodArgument
  end
end
