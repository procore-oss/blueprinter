# frozen_string_literal: true

require 'blueprinter/v2/specification'

module Blueprinter
  module V2
    # Base class for V2 Blueprints
    class Base
      extend DSL
      extend Rendering
      extend Reflection

      class << self
        # @return [Symbol] The name of this view (`:default`, `:foo`)
        attr_accessor :view_name
        # @return [Symbol] The full name of this view, including any parent views (`:default`, `:foo`, `:foo.bar`)
        attr_accessor :view_path
        # @return [String] The fully-qualified name (`MyBlueprint`, `MyBlueprint.foo.bar`)
        attr_accessor :blueprint_name
        # @!visibility private
        attr_accessor :nodes

        # Initialize subclass
        def inherited(subclass)
          subclass.nodes = []
          subclass.children = { default: subclass }
          subclass.blueprint_name = subclass.name || blueprint_name
          subclass.view_path = :default
          subclass.view_name = :default
          subclass.eval_mutex = Mutex.new
          subclass.children_mutex = Mutex.new
        end

        def serializer
          eval! unless evaled?
          @serializer
        end

        # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
        def inspect = blueprint_name

        # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
        def to_s = blueprint_name

        #
        # Access a child view.
        #
        #   MyBlueprint[:extended]
        #   MyBlueprint["extended.plus"] or MyBlueprint[:extended][:plus]
        #
        # @param name [Symbol|String] Name of the view, e.g. :extended, "extended.plus"
        # @return [Class] A descendent of Blueprinter::V2::Base
        #
        def [](name)
          name, name_tail = name.to_s.split('.', 2)
          name = name.to_sym

          unless children.key? name
            children_mutex.synchronize do
              next if children.key? name

              # If the Blueprint has already been evaluated, throw an error if the view isn't defined.
              # Otherwise, create a child that *may* be removed post-eval if it's found to be invalid.
              # This allows Blueprints to reference their own views in associations (without using a Proc).
              invalid = evaled? && !spec.view_defs.key?(name)
              raise Errors::UnknownView, "View '#{name}' not found in Blueprint '#{self}'" if invalid

              child = Class.new(self)
              child.blueprint_name = "#{child.blueprint_name}.#{name}"
              child.view_path = child.blueprint_name.sub(/^[^.]+\./, '').to_sym
              child.view_name = name
              children[name] = child
            end
          end

          child = children.fetch(name)
          name_tail ? child[name_tail] : child
        end

        # Returns (generating if necessary) the evaluated Blueprint specification
        # @!visibility private
        # @return [Blueprinter::V2::Specification::Spec]
        def spec
          eval! unless @spec
          @spec
        end

        # Apply partials and field exclusions
        # @api private
        def eval!(lock: true)
          return if evaled? || self == V2::Base

          if lock
            eval_mutex.synchronize { run_eval! unless evaled? }
          else
            run_eval!
          end
        end

        protected

        # @!visibility private
        attr_writer :children, :eval_mutex, :children_mutex

        private

        attr_reader :children, :eval_mutex, :children_mutex
        attr_writer :spec

        def run_eval!
          superclass.eval!
          self.spec = Specification.new(self).generate
          nodes.clear.freeze
          cleanup_children!
          @serializer = Serializer.new(self)
        end

        # Before eval we allow Base#[] to accept any view name. (This allows Blueprints to self-reference their own views
        # on associations.) After eval, we know which ones weren't valid.
        def cleanup_children!
          spec.view_defs.each_key { |name| self[name] } # ensure all child classes are created
          children_mutex.synchronize do
            children.delete_if { |name| !spec.view_defs.key?(name) && name != :default }
            children.freeze
          end
        end

        def evaled? = !@serializer.nil?
      end

      self.nodes = [].freeze
      self.spec = Specification::Spec
                  .new(nodes: [], options: {}, extensions: [], formatters: {}, schema: {}, view_defs: {}).freeze
      self.blueprint_name = name
      self.view_path = :default
      self.view_name = :default

      # @return [Hash] Copy of options set on the class. Frozen after `around_blueprint_init` hooks run.
      attr_reader :options

      # @!visibility private
      def initialize
        @options = self.class.spec.options.dup
      end

      # A descriptive name for the Blueprint view, e.g. "#<WidgetBlueprint.extended>"
      def inspect = self.class.to_s

      # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
      def to_s = self.class.to_s
    end
  end
end
