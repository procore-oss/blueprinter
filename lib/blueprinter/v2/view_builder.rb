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

      # @param parent [Class] A subclass of Blueprinter::V2::Base
      def initialize(parent)
        @parent = parent
        @views = { default: @parent }
        @mut = Mutex.new
      end

      #
      # Return, and build if necessary, the view.
      #
      # @param name [Symbol] Name of the view
      # @return [Class] An anonymous subclass of @parent
      #
      def [](name)
        name = name.to_sym
        if !@views.key?(name) && view_defs.key?(name)
          @mut.synchronize do
            next if @views.key?(name)

            view = Class.new(@parent)
            @views[name] = view
            build_view view, name
            view.eval!(lock: false)
          end
        end
        @views[name]
      end

      # Works like Hash#fetch
      def fetch(name)
        self[name] || raise(KeyError, "View '#{name}' not found")
      end

      # Yield each name and view
      def each(&block)
        enum = Enumerator.new do |y|
          y.yield(:default, self[:default])
          view_defs.each_key { |name| y.yield(name, self[name]) }
        end
        block ? enum.each(&block) : enum
      end

      private

      def view_defs
        @view_defs || @mut.synchronize do
          next @view_defs if @view_defs

          @view_defs = @parent.nodes.grep(DSL::Nodes::View).each_with_object({}) do |node, acc|
            acc[node.name] ||= []
            acc[node.name] << node.block if node.block
          end
        end
      end

      def build_view(view, name)
        defs = view_defs[name]
        view.blueprint_name = "#{view.blueprint_name}.#{name}"
        view.view_path = view.blueprint_name.sub(/^[^.]+\./, '').to_sym
        view.view_name = name
        defs.each { |d| view.class_eval(&d) }
      end
    end
  end
end
