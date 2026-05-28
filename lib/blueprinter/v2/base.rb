# frozen_string_literal: true

require 'set'

module Blueprinter
  module V2
    # Base class for V2 Blueprints
    class Base
      extend DSL
      extend Rendering
      extend Reflection

      class << self
        # @return [Symbol] The name of this view, e.g. :default, :"foo.bar"
        attr_accessor :view_name
        # @return [String] The fully-qualified name, e.g. "MyBlueprint", or "MyBlueprint.foo.bar"
        attr_accessor :blueprint_name
        # @!visibility private
        attr_reader :views, :schema, :formatters, :_options, :_extensions

        # Initialize subclass
        def inherited(subclass)
          subclass.nodes = []
          subclass.views = views.dup_for(subclass)
          subclass._extensions = [].freeze
          subclass._options = {}.freeze
          subclass.blueprint_name = subclass.name || blueprint_name
          subclass.view_name = :default
          subclass.eval_mutex = Mutex.new
        end

        def serializer
          eval! unless @serializer
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
          eval! unless @serializer
          child, children = name.to_s.split('.', 2)
          view = views[child.to_sym] || raise(Errors::UnknownView, "View '#{child}' not found in Blueprint '#{self}'")
          children ? view[children] : view
        end

        # Apply partials and field exclusions
        # @api private
        def eval!(lock: true)
          return if @serializer || self == V2::Base

          if lock
            eval_mutex.synchronize { run_eval! unless @serializer }
          else
            run_eval!
          end
        end

        protected

        # @!visibility private
        attr_accessor :nodes
        # @!visibility private
        attr_writer :views, :schema, :formatters, :eval_mutex, :_options, :_extensions

        private

        attr_reader :eval_mutex

        def run_eval!
          superclass.eval!
          nodes.unshift(*inherited_partials)
          self.nodes = expand_use
          nodes.unshift(*inherited_formats, *inherited_fields).freeze

          self._options = apply(DSL::Nodes::Options, superclass._options).freeze
          self._extensions = apply(DSL::Nodes::Extensions, superclass._extensions).freeze
          self.formatters = nodes.grep(DSL::Nodes::Format).to_h { |n| [n.klass, n.fmt] }.freeze
          self.schema = nodes.grep(Fields::Field).to_h { |n| [n.name, n] }.freeze
          @serializer = Serializer.new(self)
        end

        def inherited_partials = superclass.nodes.grep(DSL::Nodes::Partial)
        def inherited_formats = superclass.nodes.grep(DSL::Nodes::Format)
        def inherited_fields = exclude_fields superclass.nodes.grep(Fields::Field)

        def apply(type, start)
          nodes.grep(type).each_with_object(start.dup) do |node, acc|
            node.block.call(acc)
          end
        end

        def expand_use(partials: self.partials, exclude_all: exclude_all?, excluded: excluded_fields)
          nodes.each_with_object([]) do |node, acc|
            unless node.is_a? DSL::Nodes::Use
              acc << node
              next
            end

            p = partials[node.name] || raise(Errors::UnknownPartial, "No '#{node.name}' partial in Blueprint '#{self}'")
            self.nodes = []
            class_eval(&p)
            self.nodes = exclude_fields(nodes, exclude_all:, excluded:)

            exclude_all ||= exclude_all?
            excluded += excluded_fields
            partials = partials.merge(self.partials)
            acc.concat(expand_use(partials:, exclude_all:, excluded:))
          end
        end

        def exclude_fields(nodes, exclude_all: exclude_all?, excluded: excluded_fields)
          nodes.reject { |n| n.is_a?(Fields::Field) && (exclude_all || excluded.include?(n.name)) }
        end

        def excluded_fields = Set.new(nodes.grep(DSL::Nodes::Exclude).map(&:name))

        def exclude_all? = nodes.grep(DSL::Nodes::Flag).any? { |n| n.name == :exclude_all }

        def partials = nodes.grep(DSL::Nodes::Partial).to_h { |n| [n.name, n.block] }
      end

      self.views = ViewBuilder.new(self)
      self.nodes = [].freeze
      self._extensions = [].freeze
      self._options = {}.freeze
      self.blueprint_name = name
      self.view_name = :default
      self.eval_mutex = Mutex.new

      # @return [Hash] Copy of options set on the class. Frozen after `around_blueprint_init` hooks run.
      attr_reader :options

      # @!visibility private
      def initialize
        @options = self.class._options.dup
      end

      # A descriptive name for the Blueprint view, e.g. "#<WidgetBlueprint.extended>"
      def inspect = self.class.to_s

      # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
      def to_s = self.class.to_s
    end
  end
end
