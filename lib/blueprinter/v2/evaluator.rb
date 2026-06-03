# frozen_string_literal: true

require 'set'

module Blueprinter
  module V2
    # Evaluates a Blueprint's AST nodes
    # @!visibility private
    class Evaluator
      attr_reader :nodes

      def initialize(blueprint)
        self.blueprint = blueprint
        self.nodes = inherit(DSL::Nodes::Partial) + blueprint.nodes
        self.nodes = expand_use
        nodes.unshift(*inherit(DSL::Nodes::Format), *inherit_fields, *inherit_views)
        nodes.freeze
      end

      # Returns the declared options for this blueprint/view
      def options
        nodes.each_with_object(blueprint.superclass.options.dup) do |node, acc|
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

      # Returns the declared extensions for this blueprint/view
      # rubocop:disable Metrics/CyclomaticComplexity
      def extensions
        nodes.each_with_object(blueprint.superclass.extensions.dup) do |node, acc|
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

      # Returns the declared formatters for this blueprint/view
      def formatters
        nodes.grep(DSL::Nodes::Format).to_h { |n| [n.klass, n.fmt] }
      end

      # Returns the declared fields and associations for this blueprint/view
      def fields
        nodes.grep(Fields::Field).to_h { |n| [n.name, n] }.freeze
      end

      # Returns a Hash of view definition blocks keyed by name
      def view_defs
        nodes.grep(DSL::Nodes::View).each_with_object({}) do |node, acc|
          acc[node.name] ||= []
          acc[node.name] << node.block if node.block
        end
      end

      private

      attr_accessor :blueprint
      attr_writer :nodes

      # Return nodes, replacing any `use` nodes with the partial's nodes
      def expand_use(partials: self.partials, exclude_all: exclude_all?, excluded: excluded_fields)
        nodes.each_with_object([]) do |node, acc|
          # Leave other node types as-is
          unless node.is_a? DSL::Nodes::Use
            acc << node
            next
          end

          # Eval the partial, temporarily leaving `blueprint.nodes` and `self.nodes` holding only the partial's nodes
          p = partials[node.name] || raise(Errors::UnknownPartial, "No '#{node.name}' partial in Blueprint '#{blueprint}'")
          blueprint.nodes = []
          blueprint.class_eval(&p)
          self.nodes = exclude_fields(blueprint.nodes, exclude_all:, excluded:)

          # Gather up any exclusions and partials defined by the partial (to be used on the next run)
          exclude_all ||= exclude_all?
          excluded += excluded_fields
          partials = partials.merge(self.partials)

          # Call `expand_use` again on the partial's nodes, in case the partial used partials. Then append to all nodes.
          acc.concat(expand_use(partials:, exclude_all:, excluded:))
        end
      end

      # Return nodes with certain (or all) field nodes excluded
      def exclude_fields(nodes, exclude_all: exclude_all?, excluded: excluded_fields)
        nodes.reject { |n| n.is_a?(Fields::Field) && (exclude_all || excluded.include?(n.name)) }
      end

      def exclude_all? = nodes.grep(DSL::Nodes::Flag).any? { |n| n.name == :exclude_all }
      def excluded_fields = Set.new(nodes.grep(DSL::Nodes::Exclude).map(&:name))

      def inherit_fields = exclude_fields inherit(Fields::Field)
      def inherit_views = blueprint.view_name == :default ? inherit(DSL::Nodes::View) : []
      def inherit(node_type) = blueprint.superclass.nodes.grep(node_type)

      # Returns a Hash of partial blocks, keyed by name
      def partials = nodes.grep(DSL::Nodes::Partial).to_h { |n| [n.name, n.block] }
    end
  end
end
