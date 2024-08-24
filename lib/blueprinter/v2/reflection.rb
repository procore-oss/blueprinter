# frozen_string_literal: true

require 'blueprinter/v2/association'
require 'blueprinter/v2/field'

module Blueprinter
  class V2
    # API for reflecting on Blueprints
    module Reflection
      #
      # Returns a Hash of views keyed by name.
      #
      # @return [Hash<Symbol, Blueprinter::V2::Reflection::View>]
      #
      def reflections
        eval! unless @evaled
        @reflections ||= flatten_children(self, :default)
      end

      # Builds a flat Hash of nested views
      # @api private
      def flatten_children(parent, child_name, path = [])
        ref_key = path.empty? ? child_name : path.join('.').to_sym
        child_view = parent.views.fetch(child_name)
        child_ref = View.new(child_view, ref_key)

        child_view.views.reduce({ ref_key => child_ref }) do |acc, (name, _)|
          children = name == :default ? {} : flatten_children(child_view, name, path + [name])
          acc.merge(children)
        end
      end

      #
      # Represents a view within a Blueprint.
      #
      class View
        # @return [Symbol] Name of the view
        attr_reader :name
        # @return [Hash<Symbol, Blueprinter::V2::Field>] Fields defined on the view
        attr_reader :fields
        # @return [Hash<Symbol, Blueprinter::V2::Association>] Associations defined on the view
        attr_reader :associations


        # @param blueprint [Class] A subclass of Blueprinter::V2
        # @param name [Symbol] Name of the view
        # @api private
        def initialize(blueprint, name)
          @name = name
          @fields = blueprint.fields.select { |_, f| f.is_a? Field }
          @associations = blueprint.fields.select { |_, f| f.is_a? Association }
        end
      end
    end
  end
end
