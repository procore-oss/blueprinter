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
        initial_val = exclude_options? ? {} : blueprint.superclass.options.dup
        nodes.each_with_object(initial_val) do |node, acc|
          case node
          when DSL::Nodes::SetOpt
            acc[node.key] = node.val
          when DSL::Nodes::SetDynamicOpt
            acc[node.key] = node.block.call(acc[node.key])
          when DSL::Nodes::UnsetOpt
            acc.delete node.key
          end
        end
      end

      # Returns the declared extensions for this blueprint/view
      def extensions
        initial_val = exclude_extensions? ? [] : blueprint.superclass.extensions.dup
        nodes.each_with_object(initial_val) do |node, acc|
          case node
          when DSL::Nodes::AppendExt
            acc.push(node.ext)
          when DSL::Nodes::PrependExt
            acc.unshift(node.ext)
          when DSL::Nodes::RemExt
            acc.reject! { |ext| ext.is_a? node.klass }
          end
        end
      end

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
      def expand_use(partials: self.partials, excluded: excluded_fields, exclude_fields: exclude_fields?,
                     exclude_options: exclude_options?, exclude_extensions: exclude_extensions?)
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
          self.nodes = exclude(blueprint.nodes, excluded:, exclude_fields:, exclude_options:, exclude_extensions:)

          # Gather up any exclusions and partials defined by the partial (to be used on the next run)
          excluded += excluded_fields
          exclude_fields ||= exclude_fields?
          exclude_options ||= exclude_options?
          exclude_extensions ||= exclude_extensions?
          partials = partials.merge(self.partials)

          # Call `expand_use` again on the partial's nodes, in case the partial used partials. Then append to all nodes.
          acc.concat(expand_use(partials:, excluded:, exclude_fields:, exclude_options:, exclude_extensions:))
        end
      end

      # Return nodes with certain (or all) field nodes excluded
      def exclude(nodes, excluded: excluded_fields, exclude_fields: exclude_fields?, exclude_options: exclude_options?,
                  exclude_extensions: exclude_extensions?)
        nodes.reject do |n|
          case n
          when Fields::Field
            exclude_fields || excluded.include?(n.name)
          when DSL::Nodes::SetOpt, DSL::Nodes::SetDynamicOpt
            exclude_options
          when DSL::Nodes::AppendExt, DSL::Nodes::PrependExt
            exclude_extensions
          else
            false
          end
        end
      end

      def exclude_options? = flag? :exclude_options
      def exclude_extensions? = flag? :exclude_extensions
      def exclude_fields? = flag? :exclude_fields
      def excluded_fields = Set.new(nodes.grep(DSL::Nodes::Exclude).map(&:name))
      def flag?(name) = nodes.grep(DSL::Nodes::Flag).any? { |n| n.name == name }

      def inherit_fields = exclude inherit(Fields::Field)
      def inherit_views = blueprint.view_name == :default ? inherit(DSL::Nodes::View) : []
      def inherit(node_type) = blueprint.superclass.nodes.grep(node_type)

      # Returns a Hash of partial blocks, keyed by name
      def partials = nodes.grep(DSL::Nodes::Partial).to_h { |n| [n.name, n.block] }
    end
  end
end
