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
        @views = { default: parent }
        @pending = {}
        @mut = Mutex.new
      end

      #
      # Add a view definition.
      #
      # @param name [Symbol]
      # @param definition [Proc]
      #
      def []=(name, definition)
        @pending[name.to_sym] = definition
      end

      #
      # Return, and build if necessary, the view.
      #
      # @param name [Symbol] Name of the view
      # @return [Class] An anonymous subclass of @parent
      #
      def [](name)
        name = name.to_sym
        if !@views.key?(name) && @pending.key?(name)
          @mut.synchronize do
            next if @views.key?(name)

            view = Class.new(@parent)
            view.append_name(name)
            view.class_eval(&@pending[name]) if @pending[name]
            view.eval!(lock: false)
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
    end
  end
end
