# Telemetry

Blueprinter bundles the `Blueprinter::Extensions::OpenTelemetry` extension. But if that doesn't work with your tooling, build your own!

```ruby
class MyTelemetryExtension
  def initialize(my_tel)
    @my_tel = my_tel
  end

  # Create a span for object serialization
  def around_serialize_object(ctx)
    @my_tel.span("blueprint.object", blueprint: ctx.blueprint.to_s) do
      yield ctx
    end
  end

  # Create a span for collection serialization
  def around_serialize_collection(ctx)
    @my_tel.span("blueprint.collection", blueprint: ctx.blueprint.to_s) do
      yield ctx
    end
  end

  # Create a span for other extension hooks
  def around_hook(ctx)
    @my_tel.span("blueprint.extension", extension: ctx.extension.class.name, hook: ctx.hook) do
      yield
    end
  end

  # Prevent `around_hook` from running around this extension's own hooks
  def hidden? = true
end
```
