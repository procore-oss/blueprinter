module Blueprinter
  # @api private
  module View
    class Builder
      attr_reader :ancestors

      def initialize
        @ancestors = {
          identifier: [:identifier], default: [:identifier, :default]
        }
      end

      def build(view, with: :default)
        ancestor_view = with
        current_ancestors = ancestors.fetch(ancestor_view, [ancestor_view])
        ancestors[view] = current_ancestors + [view]
        reinherit_views(view)
      end

      def include?(view)
        !!ancestors[view]
      end

      private

      def reinherit_views(target_view)
        ancestors.each do |view, ancestor_views|
          next if view == target_view || !ancestor_views.include?(target_view)
          ancestors[view] = ancestors[view] | ancestors[target_view]
        end
      end
    end
  end
end
