# frozen_string_literal: true

module Blueprinter
  module V2
    #
    # A Hash-like class that holds a Blueprint's views, but defers evaluation of their
    # definitions until they're first accessed.
    #
    # This allows views to trivially inherit parent fields, etc even when they're defined AFTER the view.
    #
    class ViewBuilder
      include Enumerable

      Def = Struct.new(:definition, :fields, :options, :extensions, keyword_init: true)

      # @param parent [Class] A subclass of Blueprinter::V2::Base

      def initialize(parent)
        @parent = parent
        @mut = Mutex.new
        reset
      end

      #
      # Add a view definition.
      #
      # @param name [Symbol]
      # @param definition [Blueprinter::V2::ViewBuilder::Def]
      #
      def []=(name, definition)
        name = name.to_sym
        raise Errors::InvalidBlueprint, "You may not redefine the default view" if name == :default

        @pending[name] = definition
      end

      #
      # Return, and build if necessary, the view.
      #
      # @param name [Symbol] Name of the view
      # @return [Class] An anonymous subclass of @parent
      #
      def [](name)
        name = name.to_sym
        if !@views.key?(name) and @pending.key?(name)
          @mut.synchronize do
            next if @views.key?(name)

            p = @pending[name]
            view = Class.new(@parent)
            view.views.reset
            view.append_name(name)
            view.schema.clear unless p.fields
            view.options.clear unless p.options
            view.extensions.clear unless p.extensions
            view.class_eval(&p.definition) if p.definition
            view.eval!(false)
            @views[name] = view
          end
        end
        @views[name]
      end

      # Works like Hash#fetch
      def fetch(name)
        self[name] || raise(KeyError, "View '#{name}' not found")
      end

      def each(&block)
        enum = Enumerator.new do |y|
          y.yield(:default, self[:default])
          @pending.each_key { |name| y.yield(name, self[name]) }
        end
        block ? enum.each(&block) : enum
      end

      # Create a duplicate of this builder with a different default view
      def dup_for(blueprint)
        builder = self.class.new(blueprint)
        @pending.each { |name, definition| builder[name] = definition }
        builder
      end

      # Clear everything but the default view
      def reset
        @views = { default: @parent }
        @pending = {}
      end
    end
  end
end
