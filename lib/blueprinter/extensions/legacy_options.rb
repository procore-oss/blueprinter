# frozen_string_literal: true

require 'blueprinter/empty_types'

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
    # When an if/unless Proc can accept three arguments, it will be treated like V1. V2 if/unless Procs take
    # a single argument. Like V1, the first argument is the field's name in the result, i.e. the `name` option
    # if there is one.
    #
    # ```
    # # V1 style
    # field :foo, if: ->(_field_name, object, _options) { object.show_foo? }
    #
    # # V2 style
    # field :bar, if: ->(ctx) { ctx.object.show_bar? }
    # ```
    #
    # Method names are treated like V1 when the Blueprint defines a *class* method of that name which can accept
    # three arguments. V2 if/unless methods are *instance* methods which take a single argument.
    #
    # ```
    # # V1 style
    # field :foo, if: :show_foo?
    #
    # def self.show_foo?(_field_name, object, _options) = object.show_foo?
    #
    # # V2 style
    # field :bar, if: :show_bar?
    #
    # def show_bar?(ctx) = ctx.object.show_bar?
    # ```
    #
    # In the V2 examples, `ctx` is a {Blueprinter::V2::Context::Field}.
    #
    # === default_if
    #
    # When `default_if` is passed a V1 constant (`EMPTY_STRING`, `EMPTY_HASH`, `EMPTY_COLLECTION`), it will
    # be treated like V1. V2 takes a Proc or method name. Also like V1, a V1 `default_if` with no `default`
    # option defaults to `nil`.
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
    # Support for Legacy/V1's `extractor` option. Like V1, the extractor may be a class or an instance, it's
    # instantiated at most once per render, and the field's block (if any) is passed to it in the `block` option.
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
    # As in V1, the option remains in the options Hash that's passed to conditionals, extractors, and field blocks.
    #
    # == Known incompatibilities
    #
    # V2 never reads V1's global configuration, so the V1 options that fall back to it can't be fully reproduced
    # here. Declare the equivalent option on a Blueprint instead — on an `ApplicationBlueprint` that the rest of
    # your Blueprints inherit from, if you want it applied globally.
    #
    # `Blueprinter.configuration.field_default` is ignored. A V1 `default_if` with no `default` option defaults to
    # `nil`, which is what the config itself defaults to.
    #
    # ```
    # # V1 style
    # Blueprinter.configure { |config| config.field_default = "N/A" }
    #
    # # V2 style
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   set :default, "N/A"
    # end
    # ```
    #
    # `Blueprinter.configuration.if` and `Blueprinter.configuration.unless` are ignored too.
    #
    # ```
    # # V1 style
    # Blueprinter.configure { |config| config.if = ->(_field_name, object, _options) { object.visible? } }
    #
    # # V2 style
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   set :if, ->(ctx) { ctx.object.visible? }
    # end
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
        # Unlike V1, the option is left in place so that conditionals, extractors, and blocks can read it. Comparing
        # it to the current view also keeps us from looping, since replacing the Blueprint restarts the render.
        view = ctx.options[:view]
        ctx.blueprint = ctx.blueprint.class[view].new if view && ctx.blueprint.class.view_path.to_s != view.to_s
        yield ctx
      end

      # @param ctx [Blueprinter::V2::Context::Init]
      # @!visibility private
      def init_legacy_conditionals(ctx)
        blueprint = ctx.blueprint.class
        opts = ctx.blueprint.options

        # Convert blueprint if/unless options
        opts[:if] = wrap_v1_cond(opts[:if], blueprint) if opts[:if]
        opts[:unless] = wrap_v1_cond(opts[:unless], blueprint) if opts[:unless]

        # Convert field if/unless options
        ctx.fields.each do |field|
          field.options[:if] = wrap_v1_cond(field.options[:if], blueprint) if field.options[:if]
          field.options[:unless] = wrap_v1_cond(field.options[:unless], blueprint) if field.options[:unless]
        end
        yield ctx
      end

      # @param ctx [Blueprinter::V2::Context::Init]
      # @!visibility private
      def init_legacy_default_ifs(ctx)
        blueprint_opts = ctx.blueprint.options

        # Convert blueprint default_if option
        apply_v1_default_if(blueprint_opts, blueprint_opts)

        # Convert field default_if options
        ctx.fields.each { |field| apply_v1_default_if(field.options, blueprint_opts) }
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
          extractor = field.options[:extractor] || default_extractor
          next if extractor.nil?

          # Like V1, instantiate the extractor once and hand the field's block to it in the options
          extractor = extractor.new if extractor.is_a? Class
          options = field.options.merge(block: field.block)
          field.block = proc { |obj, fctx| extractor.extract(fctx.field.source, obj, fctx.options, options) }
        end
        yield ctx
      end

      private

      def wrap_v1_cond(cond, blueprint)
        v1_callable =
          case cond
          when Proc then cond if v1_cond_args?(cond)
          when Symbol, String then v1_cond_method(cond, blueprint)
          end
        return cond if v1_callable.nil?

        # V1 passes the field's name in the result, which may differ from its source
        ->(ctx) { v1_callable.call(ctx.field.name, ctx.object, ctx.options) }
      end

      # V1 if/unless method names refer to class methods which take the field name, object, and options.
      # V2's refer to instance methods which take a single Context::Field.
      def v1_cond_method(name, blueprint)
        return nil unless blueprint.respond_to?(name, true)

        method = blueprint.method(name)
        # Ignore the class methods every Blueprint has (`render`, `inspect`, `format`, etc)
        return nil unless user_defined_ancestors(blueprint).include? method.owner

        method if v1_cond_args?(method)
      end

      # Modules/singleton classes that define class methods this Blueprint didn't inherit from V2::Base
      def user_defined_ancestors(blueprint)
        blueprint.singleton_class.ancestors - ::Blueprinter::V2::Base.singleton_class.ancestors
      end

      # True if the callable can accept the three arguments V1 passes to conditionals. V2 conditionals accept one.
      def v1_cond_args?(callable)
        types = callable.parameters.map(&:first)
        return types.count(:req) <= V1_COND_ARITY if types.include? :rest

        V1_COND_ARITY.between?(types.count(:req), types.count(:req) + types.count(:opt))
      end

      # V1 applies the default value whenever `default_if` matches, even when there's no `default` option. V2 ignores
      # `default_if` unless a `default` was set.
      def apply_v1_default_if(opts, blueprint_opts)
        default_if = opts[:default_if]
        return if default_if.nil?

        cond = v1_default_if(default_if)
        return if cond.nil?

        opts[:default_if] = cond
        return if opts.key?(:default) || blueprint_opts.key?(:default)

        opts[:default] = nil
      end

      def v1_default_if(cond)
        case cond
        when ::Blueprinter::EMPTY_COLLECTION, ::Blueprinter::EMPTY_HASH, ::Blueprinter::EMPTY_STRING
          ->(_ctx, value) { EmptyTypes.send(:use_default_value?, value, cond) }
        end
      end
    end
  end
end
