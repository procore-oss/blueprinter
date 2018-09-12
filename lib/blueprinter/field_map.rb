module Blueprinter
  # @api private

  class FieldMap

    def initialize
      @ancestors = {
        identifier: [:identifier], default: [:identifier, :default]
      }
      @fields = { identifier: [], default: [] }
      @excluded_fields = {}
      @composed_fields = {}
    end

    def include_view(view, ancestor_view = :default)
      current_ancestors = @ancestors.fetch(ancestor_view, [ancestor_view])
      @ancestors[view] = current_ancestors + [view]
      reinherit_views(view)
      compose
    end

    def exclude_field(view, field_name)
      @excluded_fields[view] = @excluded_fields.fetch(view, []) + [field_name]
      compose
    end

    def add_field(view, field)
      include_view(view) unless @ancestors[view]
      @fields[view] = @fields.fetch(view, []) + [field]
      compose
    end

    def set_field(view, field)
      @fields[view] = [field]
      compose
    end

    def fields_for(view)
      @composed_fields[view]
    end

    private

    def reinherit_views(target_view)
      @ancestors.each do |view, ancestor_views|
        next if view == target_view || !ancestor_views.include?(target_view)
        @ancestors[view] = @ancestors[view] | @ancestors[target_view]
      end
    end

    def compose
      @composed_fields = @ancestors.inject({}) do |acc, (view, ancestor_views)|
        acc[view] = ancestor_views.inject([]) do |arr, ancestor_view|
          arr += @fields.fetch(ancestor_view, [])
          arr.delete_if do |field|
            @excluded_fields.fetch(ancestor_view, []).include? field.method
          end
          arr
        end.sort_by { |f| [@fields[:identifier].include?(f) ? 0 : 1, f.name] }
        acc
      end
    end
  end
end
