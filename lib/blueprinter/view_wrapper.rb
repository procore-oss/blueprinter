module Blueprinter
  # Wraps a V1 Blueprint and view into a single object with a Blueprint interface. Used by V2 interop.
  class ViewWrapper
    attr_reader :blueprint, :view_name

    def initialize(blueprint, view_name)
      @blueprint = blueprint
      @view_name = view_name
    end

    def render(object, options = {})
      blueprint.render(object, { view: view_name }.merge(options))
    end

    def render_as_hash(object, options = {})
      blueprint.render_as_hash(object, { view: view_name }.merge(options))
    end

    def render_as_json(object, options = {})
      blueprint.render_as_json(object, { view: view_name }.merge(options))
    end

    def reflections
      blueprint.reflections
    end
  end
end
