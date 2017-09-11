module PaintedRabbit
  class ViewCollection
    attr_reader :views
    def initialize
      @views = {
        identifier: View.new,
        default: View.new
      }
    end

    def has_view?(view_name)
      views.has_key? view_name
    end

    def render_fields(key)
      views[:identifier].fields +
        views[:default].fields.concat(views[key].fields).sort_by(&:name)
    end

    def [](key)
      @views[key] ||= View.new
    end
  end
end
