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
        attr_reader :views, :schema, :formatters, :options, :extensions

        # Initialize subclass
        def inherited(subclass)
          subclass.nodes = []
          subclass.views = views.dup_for(subclass)
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
        attr_writer :views, :eval_mutex

        private

        attr_reader :eval_mutex
        attr_writer :options, :extensions, :schema, :formatters

        def run_eval!
          superclass.eval!
          nodes.unshift(*inherited_partials)
          self.nodes = expand_use
          nodes.unshift(*inherited_formats, *inherited_fields).freeze

          self.options = eval_options.freeze
          self.extensions = eval_extensions.freeze
          self.formatters = nodes.grep(DSL::Nodes::Format).to_h { |n| [n.klass, n.fmt] }.freeze
          self.schema = nodes.grep(Fields::Field).to_h { |n| [n.name, n] }.freeze
          @serializer = Serializer.new(self)
        end

        def inherited_partials = superclass.nodes.grep(DSL::Nodes::Partial)
        def inherited_formats = superclass.nodes.grep(DSL::Nodes::Format)
        def inherited_fields = exclude_fields superclass.nodes.grep(Fields::Field)

        # Return nodes, replacing any `use` nodes with the partial's nodes
        def expand_use(partials: self.partials, exclude_all: exclude_all?, excluded: excluded_fields)
          nodes.each_with_object([]) do |node, acc|
            # Leave other node types as-is
            unless node.is_a? DSL::Nodes::Use
              acc << node
              next
            end

            # Eval the partial, temporarily leaving `self.nodes` holding only the partial's nodes
            p = partials[node.name] || raise(Errors::UnknownPartial, "No '#{node.name}' partial in Blueprint '#{self}'")
            self.nodes = []
            class_eval(&p)
            self.nodes = exclude_fields(nodes, exclude_all:, excluded:)

            # Gather up any exclusions and partials defined by the partial (to be used on the next run)
            exclude_all ||= exclude_all?
            excluded += excluded_fields
            partials = partials.merge(self.partials)

            # Call `expand_use` again on the partial's nodes, in case the partial used partials. Then append to all nodes.
            acc.concat(expand_use(partials:, exclude_all:, excluded:))
          end
        end

        def eval_options
          nodes.each_with_object(superclass.options.dup) do |node, acc|
            case node
            when DSL::Nodes::SetOpt
              acc[node.key] = node.val
            when DSL::Nodes::SetDynamicOpt
              acc[node.key] = node.block.call(acc[node.key])
            when DSL::Nodes::UnsetOpt
              acc.delete node.key
            when DSL::Nodes::Flag
              acc.clear if node.name == :unset_all
            end
          end
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def eval_extensions
          nodes.each_with_object(superclass.extensions.dup) do |node, acc|
            case node
            when DSL::Nodes::AppendExt
              acc.push(node.ext)
            when DSL::Nodes::PrependExt
              acc.unshift(node.ext)
            when DSL::Nodes::RemExt
              acc.reject! { |ext| ext.is_a? node.klass }
            when DSL::Nodes::Flag
              acc.clear if node.name == :remove_all
            end
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def exclude_fields(nodes, exclude_all: exclude_all?, excluded: excluded_fields)
          nodes.reject { |n| n.is_a?(Fields::Field) && (exclude_all || excluded.include?(n.name)) }
        end

        def excluded_fields = Set.new(nodes.grep(DSL::Nodes::Exclude).map(&:name))

        def exclude_all? = nodes.grep(DSL::Nodes::Flag).any? { |n| n.name == :exclude_all }

        def partials = nodes.grep(DSL::Nodes::Partial).to_h { |n| [n.name, n.block] }
      end

      self.views = ViewBuilder.new(self)
      self.nodes = [].freeze
      self.extensions = [].freeze
      self.options = {}.freeze
      self.blueprint_name = name
      self.view_name = :default
      self.eval_mutex = Mutex.new

      # @return [Hash] Copy of options set on the class. Frozen after `around_blueprint_init` hooks run.
      attr_reader :options

      # @!visibility private
      def initialize
        @options = self.class.options.dup
      end

      # A descriptive name for the Blueprint view, e.g. "#<WidgetBlueprint.extended>"
      def inspect = self.class.to_s

      # A descriptive name for the Blueprint view, e.g. "WidgetBlueprint.extended"
      def to_s = self.class.to_s
    end
  end
end
