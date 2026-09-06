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
  # - [around_result](#around_result-instance_method)
  #   - [around_blueprint_init](#around_blueprint_init-instance_method)
  #     - [around_serialize_object](#around_serialize_object-instance_method) |
  #       [around_serialize_collection](#around_serialize_collection-instance_method)
  #       - [around_blueprint](#around_blueprint-instance_method)
  #         - [around_field_value](#around_field_value-instance_method) |
  #           [around_object_value](#around_object_value-instance_method) |
  #           [around_collection_value](#around_collection_value-instance_method)
  #           - [around_blueprint_init](#around_blueprint_init-instance_method)
  #             - …
  # - [around_hook](#around_hook-instance_method)
  #
  # == Extension hook arguments
  #
  # Extension hooks are passed one argument: a context object. Different hooks are passed different types of context objects,
  # but they generally include things like the current Blueprint instance, the object being serialized, and the serialization
  # depth.
  #
  # Some context objects can be modified by hooks, affecting the behavior of subsequent hooks or Blueprinter itself. (Think
  # Rack middleware.) See the {Blueprinter::V2::Context} module for full documentation about each type.
  #
  # == Extension hooks yield
  #
  # Similar to how Rack middleware calls the next middleware, Blueprinter extension hooks `yield` to the next hook,
  # ultimately yielding to Blueprinter internals.
  #
  # Some hooks require that you yield, while others allow you to skip it (e.g. a caching extension).
  #
  # == Extensions and state
  #
  # Extension instances will live for the duration of your program and may be used across threads. Generally, you should not
  # keep serialization state in your extension instance.
  #
  # If your extension needs to store and access state specific to the current serialization, use the `ctx.state` Hash. It's
  # available to all extensions during a given `render` call.
  #
  # == Extensions and performance
  #
  # Using extensions does incur some overhead. How much depends on which hooks you use, and of course what you do inside
  # them. Each hook below has a "Perf Impact" section that describes its expected performance impact.
  #
  # Many behavious can be implemented differently using different hooks. Which hook you choose can impact performance. Read
  # the
  # [Performance](https://procore-oss.github.io/blueprinter/extensions/performance.html) section of the V2 Extension Guide
  # for some examples.
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
    Hook = Struct.new(:name, :ext, :target)

    # @!visibility private
    HOOKS = %i[
      around_hook
      around_result
      around_blueprint_init
      around_serialize_object
      around_serialize_collection
      around_blueprint
      around_field_value
      around_object_value
      around_collection_value
      pre_render
    ].freeze

    # If this returns true, `around_hook` will not be called when this extension's hooks are run.
    #
    # Useful for extensions like {Blueprinter::Extensions::OpenTelemetry} that don't want to measure themselves.
    #
    # @return [true | false]
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

    # Helper for `around_result` hooks to declare that a result is "serialized" and should be passed through as-is.
    #
    # ```
    # def around_result(ctx)
    #   value = yield ctx
    #   value = modify value
    #   serialized value
    # end
    # ```
    #
    # @param val [Object] The final value
    # @return [Blueprinter::V2::Context::Serialized] `val` wrapped in a struct
    def serialized(val) = V2::Context::Serialized.new(val)

    # Helper for `around_result` hooks to check if a previous hook has declared a result "serialized" and passed through
    # as-is.
    #
    # ```
    # def around_result(ctx)
    #   value = yield ctx
    #   return value if serialized? value
    #
    #   modify value
    # end
    # ```
    #
    # @param val [Object] The value in question
    # @return [true | false]
    def serialized?(val) = val.is_a? V2::Context::Serialized

    # Freezes hooks and returns registered hooks
    # @!visibility private
    def finalize_hooks = _hooks.freeze

    private

    # Registers an `around_result` hook. `around_result` is the outermost hook, called exactly once on the Blueprint that's
    # being rendered.
    #
    # - Argument: {Blueprinter::V2::Context::Result}
    # - Yield: Optional
    # - Return: Serialized result
    # - Perf Impact: Low (run once per render)
    #
    # ```
    # def initialize = around_result :my_result_hook
    #
    # def my_result_hook(ctx)
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
    # The {Blueprinter::Extension#serialized serialized} and {Blueprinter::Extension#serialized? serialized?} helper
    # methods can be used to declare and detect serialized values (like a JSON strings) that shouldn't be further modified.
    #
    # @param name [Symbol] Name of instance method that implements hook
    # @!visibility public
    def around_result(name) = register_hook(:around_result, name)

    # Registers an `around_blueprint_init` hook. Called the first time each Blueprint is encountered during a serialization.
    #
    # - Argument: {Blueprinter::V2::Context::Init}
    # - Yield: Required
    # - Return: N/A
    # - Perf Impact: Low (run once per blueprint per render)
    #
    # ```
    # def initialize = around_blueprint_init :my_init_hook
    #
    # def my_init_hook(ctx)
    #   # optionally modify the context before yielding
    #   yield ctx
    # end
    # ```
    #
    # By modifying the context, you can sort, filter, or modify the fields that will be serialized, as well as the
    # blueprint's options. Some extensions may wish to initialize some kind of state in `ctx.state`.
    #
    # @param name [Symbol] Name of instance method that implements hook
    # @!visibility public
    def around_blueprint_init(name) = register_hook(:around_blueprint_init, name)

    # Registers an `around_serialize_object` hook. Called every time a single object is serialized. This includes an object
    # passed to `render` as well as any singular associations defined in Blueprints.
    #
    # - Argument: {Blueprinter::V2::Context::Object}
    # - Yield: Optional
    # - Return: Serialized object as a Hash
    # - Perf Impact: Medium (run for every object association)
    #
    # ```
    # def initialize = around_serialize_object :my_serialize_hook
    #
    # def my_serialize_hook(ctx)
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
    # @param name [Symbol] Name of instance method that implements hook
    # @!visibility public
    def around_serialize_object(name) = register_hook(:around_serialize_object, name)

    # Registers an `around_serialize_collection` hook. Called every time a collection of objects is serialized. This includes
    # collections passed to `render` as well as any collection associations defined in Blueprints.
    #
    # - Argument: {Blueprinter::V2::Context::Object}
    # - Yield: Optional
    # - Return: Serialized collection as an Enumerable of hashes
    # - Perf Impact: Medium (run for every collection association)
    #
    # ```
    # def initialize = around_serialize_collection :my_serialize_hook
    #
    # def my_serialize_hook(ctx)
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
    # @param name [Symbol] Name of instance method that implements hook
    # @!visibility public
    def around_serialize_collection(name) = register_hook(:around_serialize_collection, name)

    # Registers an `around_blueprint` hook. Called every time a Blueprint serializes an object. For a single object it's
    # equivalent to `around_serialize_object`. For collections it's called once per object in the collection.
    #
    # - Argument: {Blueprinter::V2::Context::Object}
    # - Yield: Optional
    # - Return: Serialized object as a Hash
    # - Perf Impact: Medium (run for every object association, N times for every collection association)
    #
    # ```
    # def initialize = around_blueprint :my_blueprint_hook
    #
    # def my_blueprint_hook(ctx)
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
    # @param name [Symbol] Name of instance method that implements hook
    # @!visibility public
    def around_blueprint(name) = register_hook(:around_blueprint, name)

    # Registers an `around_field_value` hook. Called for every non-object, non-collection field defined in the Blueprint.
    # (Skipped if a field fails its if/unless checks.)
    #
    # - Argument: {Blueprinter::V2::Context::Field}
    # - Yield: Optional
    # - Return: The extracted field value
    # - Perf Impact: High (run for every regular field)
    #
    # ```
    # def initialize = around_field_value :my_field_hook
    #
    # def my_field_hook(ctx)
    #   # optionally modify the context before yielding
    #   result = yield ctx
    #   # optionally modify the result before returning
    #   result
    # end
    # ```
    #
    # NOTE: Any {Blueprinter::V2::DSL::Data#format formatters} are called after all `around_field_value` hooks.
    #
    # The {Blueprinter::Extension#skip! skip!} helper may be used to abort field hooks and omit a field from the result.
    #
    # If you want to handle field extraction on your own, omit the `yield` and extract the value yourself using
    # {Blueprinter::V2::Context::Field#field ctx.field} and {Blueprinter::V2::Context::Field#object ctx.object}.
    #
    # @param name [Symbol] Name of instance method that implements hook
    # @!visibility public
    def around_field_value(name) = register_hook(:around_field_value, name)

    # Registers an `around_object_value` hook. Called for every object field defined in the Blueprint. (Skipped if a field
    # fails its if/unless checks.)
    #
    # - Argument: {Blueprinter::V2::Context::Field}
    # - Yield: Optional
    # - Return: The extracted object (unserialized)
    # - Perf Impact: High (run for every object field)
    #
    # ```
    # def initialize = around_object_value :my_object_hook
    #
    # def my_object_hook(ctx)
    #   # optionally modify the context before yielding
    #   result = yield ctx
    #   # optionally modify the result before returning
    #   result
    # end
    # ```
    #
    # The {Blueprinter::Extension#skip! skip!} helper may be used to abort field hooks and omit a field from the result.
    #
    # If you want to handle object extraction on your own, omit the `yield` and extract the value yourself using
    # {Blueprinter::V2::Context::Field#field ctx.field} and {Blueprinter::V2::Context::Field#object ctx.object}.
    #
    # @param name [Symbol] Name of instance method that implements hook
    # @!visibility public
    def around_object_value(name) = register_hook(:around_object_value, name)

    # Registers an `around_collection_value` hook. Called for every collection field defined in the Blueprint. (Skipped if a
    # field fails its if/unless checks.)
    #
    # - Argument: {Blueprinter::V2::Context::Field}
    # - Yield: Optional
    # - Return: The extracted collection (unserialized)
    # - Perf Impact: High (run for every collection field)
    #
    # ```
    # def initialize = around_collection_value :my_collection_hook
    #
    # def my_collection_hook(ctx)
    #   # optionally modify the context before yielding
    #   result = yield ctx
    #   # optionally modify the result before returning
    #   result
    # end
    # ```
    #
    # The {Blueprinter::Extension#skip! skip!} helper may be used to abort field hooks and omit a field from the result.
    #
    # If you want to handle collection extraction on your own, omit the `yield` and extract the value yourself using
    # {Blueprinter::V2::Context::Field#field ctx.field} and {Blueprinter::V2::Context::Field#object ctx.object}.
    #
    # @param name [Symbol] Name of instance method that implements hook
    # @!visibility public
    def around_collection_value(name) = register_hook(:around_collection_value, name)

    # Registers an `around_hook` hook. A meta hook that runs around all other extension hooks.
    #
    # It can't affect the serialized output and is most useful for instrumentation and logging. The included
    # {Blueprinter::Extensions::OpenTelemetry} extension uses it to trace other extensions.
    #
    # - Argument: {Blueprinter::V2::Context::Hook}
    # - Yield: Required (no context)
    # - Return: N/A
    # - Perf Impact: Depends heavily on which extension hooks are in use and how many. Field-level hooks will have
    # a greater performance impact than others.
    #
    # ```
    # def initialize = around_hook :my_instrumentation_hook
    #
    # def my_instrumentation_hook(ctx)
    #   my_instrumentation ctx do
    #     yield
    #   end
    # end
    # ```
    #
    # @param name [Symbol] Name of instance method that implements hook
    # @!visibility public
    def around_hook(name) = register_hook(:around_hook, name)

    def register_hook(hook_name, method_name)
      raise ArgumentError, "Invalid hook name: #{hook_name.inspect}" unless HOOKS.include? hook_name
      raise ArgumentError, "Invalid call name: #{method_name.inspect}" unless respond_to? method_name

      _hooks << Hook.new(hook_name, self, method_name).freeze
      _hooks.uniq!
    end

    def _hooks = @_hooks ||= []
  end
end
