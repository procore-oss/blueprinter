# frozen_string_literal: true

require 'blueprinter/v2/specification'

module Blueprinter
  module V2
    #
    # Base class for V2 Blueprints. See {Blueprinter::V2::DSL} for the full API.
    #
    # The following example creates two views: `:default` (top-level) and `:with_parts`, which inherits everything from
    # `:default`.
    #
    # ```
    # class WidgetBlueprint < ApplicationBlueprint
    #   field :name
    #   field :description, default: "None"
    #   association :category, CategoryBlueprint
    #
    #   view :with_parts do
    #     association :parts, [PartBlueprint]
    #   end
    # end
    # ```
    #
    # == ApplicationBlueprint
    #
    # It's good practice to define a base Blueprint for your applicaiton that defines common fields, views, options, etc.
    #
    # ```
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   set :exclude_if_nil, true
    #   add MyExtension.new
    #   format(Time) { |t| t.iso8601 }
    #
    #   field :id
    #
    #   view :identity do
    #     exclude fields: true
    #     field :id
    #   end
    #
    #   partial :timestamps do
    #     fields :created_at, :updated_at, :deleted_at
    #   end
    # end
    # ```
    #
    # == Inheritance
    #
    # Blueprints can inherit from other Blueprints. They will inherit the parent's fields, formatters, partials, views,
    # options, and extensions, and may override as necessary.
    #
    # ```
    # class SpecialzedWidgetBlueprint < WidgetBlueprint
    #   # ...
    # end
    # ```
    #
    # You can also inherit directly from another Blueprint's view:
    #
    # ```
    # class WidgetPartsBlueprint < WidgetBlueprint[:with_parts]
    #   # ...
    # end
    # ```
    #
    # == Initialization
    #
    # A Blueprint class is initialized exactly once during a given render. The instance is available through the
    # context object passed to if/unless/default Procs, field definition blocks, and extension hooks. See
    # {Blueprinter::V2::Context} for more info.
    #
    class Base
      extend DSL::Config
      extend DSL::Data
      extend DSL::Views
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
        # @!visibility private
        def inherited(subclass)
          subclass.nodes = []
          subclass.children = { default: subclass }
          subclass.blueprint_name = subclass.name || blueprint_name
          subclass.view_path = :default
          subclass.view_name = :default
          subclass.eval_mutex = Mutex.new
          subclass.children_mutex = Mutex.new
        end

        # @!visibility private
        # @return [Blueprinter::V2::Serializer]
        def serializer
          eval! unless evaled?
          @serializer
        end

        # A descriptive name for the Blueprint view (`"WidgetBlueprint.extended"`)
        def inspect = blueprint_name

        # A descriptive name for the Blueprint view (`"WidgetBlueprint.extended"`)
        def to_s = blueprint_name

        #
        # Access a child view.
        #
        #   MyBlueprint[:extended]
        #
        # Access nested views using dot syntax or nested Hash syntax.
        #
        #   MyBlueprint["extended.plus"]
        #   MyBlueprint[:extended][:plus]
        #
        # The `:default` view is an alias to the Blueprint class itself:
        #
        #   MyBluprint[:default] == MyBlueprint
        #
        # @param name [Symbol|String] Name of the view (`:extended`, `"extended.plus"`)
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

        protected

        # Apply partials and field exclusions
        # @!visibility private
        # @api private
        def eval!
          return if evaled? || self == V2::Base

          eval_mutex.synchronize do
            return if evaled?

            superclass.eval!
            self.spec = Specification.new(self).generate
            nodes.clear.freeze
            cleanup_children!
            @serializer = Serializer.new(self)
          end
        end

        # @!visibility private
        attr_writer :children, :eval_mutex, :children_mutex

        private

        attr_reader :children, :eval_mutex, :children_mutex
        attr_writer :spec

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

      # A descriptive name for the Blueprint view (`"#<WidgetBlueprint.extended>"`)
      def inspect = self.class.to_s

      # A descriptive name for the Blueprint view (`"WidgetBlueprint.extended"`)
      def to_s = self.class.to_s
    end
  end
end
