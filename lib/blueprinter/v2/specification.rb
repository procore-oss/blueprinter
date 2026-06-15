# frozen_string_literal: true

require 'set'

module Blueprinter
  module V2
    # Evaluates a Blueprint's AST nodes
    # @!visibility private
    class Specification
      Spec = Struct.new(:nodes, :options, :extensions, :formatters, :schema, :view_defs, keyword_init: true)
      Exclusions = Struct.new(:field_names, :fields, :options, :extensions, :formatters, keyword_init: true)

      def initialize(blueprint)
        self.parent = blueprint.superclass.spec
        self.blueprint = blueprint
        eval_view! if view?
        self.nodes = inherit(DSL::Nodes::Partial) + blueprint.nodes
        self.nodes = expand_partials
        nodes.unshift(*exclude(inherit(Fields::Field), parent_exclusions))
        nodes.unshift(*inherit(DSL::Nodes::View)) if blueprint?
        nodes.freeze
      end

      # Returns the full specification for a Blueprint/view
      def generate
        Spec.new(
          nodes:,
          options: options.freeze,
          extensions: extensions.freeze,
          formatters: formatters.freeze,
          schema: schema.freeze,
          view_defs: view_defs.freeze
        ).freeze
      end

      private

      attr_accessor :blueprint, :parent, :nodes

      # Returns the declared options for this blueprint/view
      def options
        initial_val = flag?(:exclude_options) ? {} : parent.options.dup
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
      # rubocop:disable Metrics/CyclomaticComplexity
      def extensions
        initial_val = flag?(:exclude_extensions) ? [] : parent.extensions.dup
        nodes.each_with_object(initial_val) do |node, acc|
          case node
          when DSL::Nodes::AppendExt
            acc.push(node.ext)
          when DSL::Nodes::PrependExt
            acc.unshift(node.ext)
          when DSL::Nodes::RemExt
            acc.reject! { |ext| ext.is_a? node.klass }
          when DSL::Nodes::RemDynamicExt
            acc.reject!(&node.block)
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      # Returns the declared formatters for this blueprint/view
      def formatters
        initial_val = flag?(:exclude_formatters) ? {} : parent.formatters.dup
        local_formatters = nodes.grep(DSL::Nodes::Format).to_h { |n| [n.klass, n.fmt] }
        initial_val.merge(local_formatters)
      end

      # Returns the declared fields and associations for this blueprint/view
      def schema
        nodes.grep(Fields::Field).to_h { |n| [n.name, n] }
      end

      # Returns a Hash of view definition blocks keyed by name
      def view_defs
        nodes.grep(DSL::Nodes::View).each_with_object({}) do |node, acc|
          acc[node.name] ||= []
          acc[node.name] << node.block if node.block
        end
      end

      # Return nodes, replacing any `use` nodes with the partial's nodes
      def expand_partials(partials = self.partials)
        nodes.each_with_object([]) do |node, acc|
          # Leave other node types as-is
          unless node.is_a? DSL::Nodes::Use
            acc << node
            next
          end

          # Eval the partial, temporarily leaving `blueprint.nodes` and `self.nodes` holding only the partial's nodes
          p = partials[node.name] ||
              raise(Errors::UnknownPartial, "No '#{node.name}' partial in Blueprint '#{blueprint}' (#{node.callsite})")
          blueprint.nodes = []
          blueprint.class_eval(&p)
          self.nodes = exclude(blueprint.nodes, node.exclusions)

          # Call `expand_partials` again on the partial's nodes, in case the partial used partials. Then append to all nodes.
          partials = partials.merge self.partials
          acc.concat(expand_partials(partials))
        end
      end

      # Return nodes with certain (or all) field nodes excluded
      def exclude(nodes, exclusions)
        nodes.reject do |n|
          case n
          when Fields::Field
            exclusions.fields || exclusions.field_names.include?(n.name)
          when DSL::Nodes::SetOpt, DSL::Nodes::SetDynamicOpt
            exclusions.options
          when DSL::Nodes::AppendExt, DSL::Nodes::PrependExt
            exclusions.extensions
          when DSL::Nodes::Format
            exclusions.formatters
          else
            false
          end
        end
      end

      # Things that should be excluded from the parent
      def parent_exclusions
        Exclusions.new(
          field_names: Set.new(nodes.grep(DSL::Nodes::Exclude).map(&:name)),
          fields: flag?(:exclude_fields),
          options: flag?(:exclude_options),
          extensions: flag?(:exclude_extensions),
          formatters: flag?(:exclude_formatters)
        )
      end

      # Grab and run this view's block(s) from the parent
      def eval_view!
        blocks = parent.view_defs[blueprint.view_name] ||
                 raise(Errors::UnknownView, "View '#{blueprint.view_name}' not found in Blueprint '#{blueprint.superclass}'")

        blocks.each { |b| blueprint.class_eval(&b) }
      end

      def view? = !blueprint?
      def blueprint? = blueprint.view_name == :default
      def flag?(name) = nodes.grep(DSL::Nodes::Flag).any? { |n| n.name == name }
      def partials = nodes.grep(DSL::Nodes::Partial).to_h { |n| [n.name, n.block] }
      def inherit(node_type) = parent.nodes.grep(node_type)
    end
  end
end
