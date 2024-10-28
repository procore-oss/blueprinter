# frozen_string_literal: true

require 'blueprinter/v2/association'
require 'blueprinter/v2/field'

module Blueprinter
  module V2
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
        # @return [Hash<Symbol, Blueprinter::V2::Association>] Associations to single objects defined on the view
        attr_reader :objects
        # @return [Hash<Symbol, Blueprinter::V2::Association>] Associations to collections defined on the view
        attr_reader :collections


        # @param blueprint [Class] A subclass of Blueprinter::V2::Base
        # @param name [Symbol] Name of the view
        # @api private
        def initialize(blueprint, name)
          @name = name
          @fields = blueprint.schema.select { |_, f| f.is_a? Field }
          @objects = blueprint.schema.select { |_, f| f.is_a?(Association) && !f.collection }
          @collections = blueprint.schema.select { |_, f| f.is_a?(Association) && f.collection }
        end
      end
    end
  end
end
