# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An extension that adds support for various V1-style options.
    #
    # ```
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   add Blueprinter::Extensions::LegacyOptions.new
    # end
    # ```
    #
    # == Supported field options
    #
    # === if/unless
    #
    # When an if/unless Proc takes three arguments, it will be treated like V1. V2 if/unless Procs take
    # a single argument.
    #
    # ```
    # # V1 style
    # field :foo, if: ->(_field_name, object, _options) { object.show_foo? }
    #
    # # V2 style
    # field :bar, if: ->(ctx) { ctx.object.show_bar? }
    # ```
    #
    # In the V2 example, `ctx` is a {Blueprinter::V2::Context::Field}.
    #
    # === default_if
    #
    # When `default_if` is passed a V1 constant (`EMPTY_STRING`, `EMPTY_HASH`, `EMPTY_COLLECTION`), it will
    # be treated like V1. V2 takes a Proc or method name.
    #
    # ```
    # # V1 style
    # field :foo, default: "foo", default_if: Blueprinter::EMPTY_STRING
    #
    # # V2 style
    # field :bar, default: "bar", default_if: ->(ctx, val) { val.empty? }
    # field :bar, default: "bar", default_if: :empty_string?
    #
    # def empty_string?(ctx, val) = val.empty?
    # ```
    #
    # In the V2 example, `ctx` is a {Blueprinter::V2::Context::Field}.
    #
    # === extractor
    #
    # Support for Legacy/V1's `extractor` option.
    #
    # ```
    # field :weird_object, extractor: MyWeirdExtractor
    # ```
    #
    # In the long term it's recommended to refactor your extractor into a V2 extension using the `around_field_value`,
    # `around_object_value`, and `around_collection_value` hooks. See {Blueprinter::Extension} for details.
    #
    # === name
    #
    # Support for V1's `name` field option.
    #
    # ```
    # # Populate the "desc" field using the object's "description"
    #
    # # V1 style
    # field :description, name: :desc
    #
    # # V2 style
    # field :desc, source: :description
    # ```
    #
    # == Supported render options
    #
    # === view
    #
    # Support's V1's `view` option passed to `render`.
    #
    # ```
    # WidgetBlueprint.render(widget, view: :extended) # V1 style
    # WidgetBlueprint[:extended].render(widget)       # V2 style
    # ```
    #
    class LegacyOptions < Extension
      # @!visibility private
      V1_COND_ARITY = 3

      def initialize
        around_result :apply_render_view_option
        around_blueprint_init :init_legacy_conditionals
        around_blueprint_init :init_legacy_default_ifs
        around_blueprint_init :init_legacy_field_names
        around_blueprint_init :init_legacy_extractors
      end

      # @param ctx [Blueprinter::V2::Context::Result]
      # @!visibility private
      def apply_render_view_option(ctx)
        if (view = ctx.options[:view])
          ctx.blueprint = ctx.blueprint.class[view].new
          ctx.options = ctx.options.except(:view).freeze
        end
        yield ctx
      end

      # @param ctx [Blueprinter::V2::Context::Init]
      # @!visibility private
      def init_legacy_conditionals(ctx)
        # Convert blueprint if/unless options
        ctx.blueprint.options[:if] = wrap_v1_cond(ctx.blueprint.options[:if]) if ctx.blueprint.options[:if]
        ctx.blueprint.options[:unless] = wrap_v1_cond(ctx.blueprint.options[:unless]) if ctx.blueprint.options[:unless]

        # Convert field if/unless options
        ctx.fields.each do |field|
          field.options[:if] = wrap_v1_cond(field.options[:if]) if field.options[:if]
          field.options[:unless] = wrap_v1_cond(field.options[:unless]) if field.options[:unless]
        end
        yield ctx
      end

      # @param ctx [Blueprinter::V2::Context::Init]
      # @!visibility private
      def init_legacy_default_ifs(ctx)
        # Convert blueprint default_if option
        if (default_if = ctx.blueprint.options[:default_if])
          ctx.blueprint.options[:default_if] = wrap_v1_default_if(default_if)
        end

        # Convert field default_if options
        ctx.fields.each do |field|
          if (default_if = field.options[:default_if])
            field.options[:default_if] = wrap_v1_default_if(default_if)
          end
        end
        yield ctx
      end

      # @param ctx [Blueprinter::V2::Context::Init]
      # @!visibility private
      def init_legacy_field_names(ctx)
        ctx.fields.each do |field|
          if (name = field.options[:name])
            field.source = field.name
            field.name = name
          end
        end
        yield ctx
      end

      # @param ctx [Blueprinter::V2::Context::Init]
      # @!visibility private
      def init_legacy_extractors(ctx)
        default_extractor = ctx.blueprint.options[:extractor]
        ctx.fields.each do |field|
          extractor_class = field.options[:extractor] || default_extractor
          next if extractor_class.nil?

          field.block = proc do |_obj, ctx|
            extractor_class.new.extract(field.source, ctx.object, ctx.options, field.options)
          end
        end
        yield ctx
      end

      private

      def wrap_v1_cond(cond)
        if cond.is_a?(Proc) && cond.arity == V1_COND_ARITY
          ->(ctx) { cond.call(ctx.field.source, ctx.object, ctx.options) }
        else
          cond
        end
      end

      def wrap_v1_default_if(cond)
        case cond
        when ::Blueprinter::EMPTY_COLLECTION, ::Blueprinter::EMPTY_HASH, ::Blueprinter::EMPTY_STRING
          ->(_ctx, value) { EmptyTypes.send(:use_default_value?, value, cond) }
        else
          cond
        end
      end
    end
  end
end
