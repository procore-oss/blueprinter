# frozen_string_literal: true

module Blueprinter
  #
  # Base class for all extensions. An extension will subclass `Blueprinter::Extension` and implement one or more hook
  # methods.
  #
  # = V2 Hooks
  #
  # V2 hooks follow a nested structure, allowing extensions to integrate deeply into the serialization lifecycle. The call
  # order of hooks looks like:
  #
  # - `around_result`
  #   - `around_blueprint_init`
  #     - `around_serialize_object` | `around_serialize_collection`
  #       - `around_field_value` | `around_object_value` | `around_collection_value`
  #         - `around_blueprint_init`
  #           - …
  # - `around_hook`
  #
  # === Extension hook arguments
  #
  # Extension hooks are passed one argument: a context object. Different hooks are passed different types of context objects,
  # but they generally include things like the current Blueprint instance, the object being serialized, and the serialization
  # depth.
  #
  # Some context objects can be modified by hooks, affecting the behavior of other hooks or Blueprinter itself. (Think Rack
  # middleware.) See the {Blueprinter::V2::Context} module for full documentation about each type.
  #
  # === Extension hook yields
  #
  # Similar to how Rack middleware calls the next middleware, Blueprinter extension hooks `yield` to the next, ultimately
  # yielding to Blueprinter internals.
  #
  # While most hooks allow you to skip yielding, a few require it.
  #
  # === Extensions and state
  #
  # Extension instances will live for the duration of your program and may be used across threads. Generally, you should not
  # keep serialization state in your extension instance.
  #
  # If your extension needs to store and access state specific to the current serialization, use the `ctx.state` Hash. It's
  # available to all extensions during a given `render` call.
  #
  # == Hook `around_result`
  #
  # The outermost hook, called exactly once per render.
  #
  # - Argument: {Blueprinter::V2::Context::Result}
  # - Yield: Optional
  # - Return: Serialized result
  #
  # ```
  # def around_result(ctx)
  #   # optionally modify the context before yielding
  #   result = yield ctx
  #   # optionally modify the result before returning
  #   result
  # end
  # ```
  #
  # By modifying the context, you can alter the object being serialized, the options, the serialization format, and even
  # the Blueprint. Some extensions may wish to initialize some kind of state in `ctx.state`. And of course you can modify
  # the result.
  #
  # The {Blueprinter::Extension#final final} and {Blueprinter::Extension#final? final?} helper
  # methods can be used to declare and detect "finalized" values (like a JSON strings)
  # that shouldn't be further modified.
  #
  # == Hook `around_blueprint_init`
  #
  # Called the first time each Blueprint is encountered during a serialization.
  #
  # - Argument: {Blueprinter::V2::Context::Init}
  # - Yield: Required
  # - Return: N/A
  #
  # ```
  # def around_blueprint_init(ctx)
  #   # optionally modify the context before yielding
  #   yield ctx
  # end
  # ```
  #
  # By modifying the context, you can sort or filter the fields that will be serialized. Some extensions may wish to
  # initialize some kind of state in `ctx.state`.
  #
  # == Hook `around_serialize_object`
  #
  # Called every time a single object is serialized. This includes an object passed to `render` as well as any singular
  # associations defined in Blueprints.
  #
  # - Argument: {Blueprinter::V2::Context::Object}
  # - Yield: Optional
  # - Return: Serialized object as a Hash
  #
  # ```
  # def around_serialize_object(ctx)
  #   # optionally modify the context before yielding
  #   result = yield ctx
  #   # optionally modify the result before returning
  #   result
  # end
  # ```
  #
  # By modifying the context, you can alter or replace the object about to be serialized. And of course you can modify
  # the result.
  #
  # == Hook `around_serialize_collection`
  #
  # Called every time a collection of objects is serialized. This includes collections passed to `render` as well as any
  # collection associations defined in Blueprints.
  #
  # - Argument: {Blueprinter::V2::Context::Object}
  # - Yield: Optional
  # - Return: Serialized collection as an Enumerable of hashes
  #
  # ```
  # def around_serialize_collection(ctx)
  #   # optionally modify the context before yielding
  #   result = yield ctx
  #   # optionally modify the result before returning
  #   result
  # end
  # ```
  #
  # By modifying the context, you can alter or replace the collection about to be serialized. And of course you can modify
  # the result.
  #
  # == Hook `around_field_value`
  #
  # Called for every non-object, non-collection field defined in the Blueprint. (Skipped if a field fails its if/unless
  # checks.)
  #
  # - Argument: {Blueprinter::V2::Context::Field}
  # - Yield: Optional
  # - Return: The extracted field value
  #
  # ```
  # def around_field_value(ctx)
  #   # optionally modify the context before yielding
  #   result = yield ctx
  #   # optionally modify the result before returning
  #   result
  # end
  # ```
  #
  # NOTE: Any {Blueprinter::V2::DSL#format formatters} are called after all `around_field_value` hooks.
  #
  # The `skip!` helper may be used to abort field hooks and omit a field from the result.
  #
  # If you want to handle field extraction on your own, omit the `yield` and extract the value yourself using
  # {Blueprinter::V2::Context::Field#field ctx.field} and {Blueprinter::V2::Context::Field#object ctx.object}.
  #
  # == Hook `around_object_value`
  #
  # Called for every object field defined in the Blueprint. (Skipped if a field fails its if/unless checks.)
  #
  # - Argument: {Blueprinter::V2::Context::Field}
  # - Yield: Optional
  # - Return: The extracted object (unserialized)
  #
  # ```
  # def around_object_value(ctx)
  #   # optionally modify the context before yielding
  #   result = yield ctx
  #   # optionally modify the result before returning
  #   result
  # end
  # ```
  #
  # The `skip!` helper may be used to abort field hooks and omit a field from the result.
  #
  # If you want to handle object extraction on your own, omit the `yield` and extract the value yourself using
  # {Blueprinter::V2::Context::Field#field ctx.field} and {Blueprinter::V2::Context::Field#object ctx.object}.
  #
  # == Hook `around_collection_value`
  #
  # Called for every collection field defined in the Blueprint. (Skipped if a field fails its if/unless checks.)
  #
  # - Argument: {Blueprinter::V2::Context::Field}
  # - Yield: Optional
  # - Return: The extracted collection (unserialized)
  #
  # ```
  # def around_collection_value(ctx)
  #   # optionally modify the context before yielding
  #   result = yield ctx
  #   # optionally modify the result before returning
  #   result
  # end
  # ```
  #
  # The `skip!` helper may be used to abort field hooks and omit a field from the result.
  #
  # If you want to handle collection extraction on your own, omit the `yield` and extract the value yourself using
  # {Blueprinter::V2::Context::Field#field ctx.field} and {Blueprinter::V2::Context::Field#object ctx.object}.
  #
  # == Hook `around_hook`
  #
  # A meta hook that runs around all other extension hooks. It can't affect the serialized output and is most
  # useful for instrumentation and logging. The included {Blueprinter::Extensions::OpenTelemetry} extension
  # uses it to trace other extensions.
  #
  # - Argument: {Blueprinter::V2::Context::Hook}
  # - Yield: Required (no context)
  # - Return: N/A
  #
  # ```
  # def around_hook(ctx)
  #   my_instrumentation ctx do
  #     yield
  #   end
  # end
  # ```
  #
  # = V1 Hooks
  #
  # == Hook `pre_render`
  #
  # Called eary during `render`, this hook receives the object to be rendered and may return a modified (or new)
  # object to be rendered.
  #
  # - Arguments:
  #   - `object [Object]` The object to be rendered
  #   - `blueprint [Class]` The Blueprinter class
  #   - `view [Symbol]` The blueprint view
  #   - `options [Hash]` Options passed to `render`
  # - Return: The object to continue rendering
  #
  # ```
  # def pre_render(object, blueprint, view, options)
  #   object
  # end
  # ```
  #
  # @api public
  #
  class Extension
    # @!visibility private
    HOOKS = %i[
      around_hook
      around_result
      around_blueprint_init
      around_serialize_object
      around_serialize_collection
      around_field_value
      around_object_value
      around_collection_value
      pre_render
    ].freeze

    # @return [Array<Symbol>] The names of the hooks implemented in this extension
    # @!visibility private
    def self.hooks
      @_hooks ||= (public_instance_methods(true) & HOOKS).freeze
    end

    # If this returns true, around_hook will not be called when this extension's hooks are run. Used by core extensions.
    # @!visibility private
    def hidden? = false

    # Skip the current field and aborts field hooks.
    #
    # Can ONLY be used with the following extension hooks:
    #
    # - `around_field_value`
    # - `around_object_value`
    # - `around_collection_value`
    #
    # ```
    # def around_field_value(ctx)
    #   value = yield ctx
    #   skip! if value.blank?
    #   value
    # end
    # ```
    def skip! = throw V2::Serializer::SIGNAL, V2::Serializer::SIG_SKIP

    # Helper for `around_result` hooks to declare that a result is "final" and should be passed through as-is.
    #
    # ```
    # def around_result(ctx)
    #   value = yield ctx
    #   value = modify value
    #   final value
    # end
    # ```
    #
    # @param val [Object] The final value
    # @return [Blueprinter::V2::Context::Final] `val` wrapped in a struct
    def final(val) = V2::Context::Final.new(val)

    # Helper for `around_result` hooks to check if a previous hook has declared a result "final" and passed through as-is.
    #
    # ```
    # def around_result(ctx)
    #   value = yield ctx
    #   return value if final? value
    #
    #   modify value
    # end
    # ```
    #
    # @param val [Object] The value in question
    # @return [true | false]
    def final?(val) = val.is_a? V2::Context::Final
  end
end
