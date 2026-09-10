# Telemetry

Blueprinter bundles the `Blueprinter::Extensions::OpenTelemetry` extension. But if that doesn't work with your tooling, build your own!

```ruby
class MyTelemetryExtension
  def initialize(my_tel, trace_extensions: true)
    @my_tel = my_tel
    around_serialize_object :trace_object
    around_serialize_collection :trace_collection
    around_hook :trace_hook if trace_extensions
  end

  # Create a span for object serialization
  # @param ctx [Blueprinter::V2::Context::Object]
  def trace_object(ctx)
    @my_tel.span("blueprint.object", blueprint: ctx.blueprint.to_s) do
      yield ctx
    end
  end

  # Create a span for collection serialization
  # @param ctx [Blueprinter::V2::Context::Object]
  def trace_collection(ctx)
    @my_tel.span("blueprint.collection", blueprint: ctx.blueprint.to_s) do
      yield ctx
    end
  end

  # Create a span for other extension hooks
  # @param ctx [Blueprinter::V2::Context::Hook]
  def trace_hook(ctx)
    @my_tel.span("blueprint.extension", extension: ctx.extension.class.name, hook: ctx.hook) do
      yield
    end
  end

  # Prevent `around_hook` from running around this extension's own hooks
  def hidden? = true
end
```
