# Extensions

Blueprinter has a powerful extension system that permits middleware throughout the entire serialization lifecycle. Some extensions are included with Blueprinter, others are available as gems, and you can easily write your own using the [Extension API](../api/extensions.md).

## Using extensions

Extensions can be added to your `ApplicationBlueprint` or any other blueprint, view, or partial. They're inherited from parent classes and views, but can be overridden.

```ruby
class MyBlueprint < ApplicationBlueprint
  # This extension instance will exist for the duration of your program
  extensions << FooExtension.new

  # These extensions will be initialized once during each render
  extensions << BarExtension
  extensions << -> { ZorpExtension.new(some_args) }

  # Inline extensions are also initialized once per render
  extension do
    def around_blueprint(ctx)
      result = yield ctx
      result.merge({ foo: "Foo" })
    end
  end

  view :minimal do
    # extensions is a simple Array, so you can add or remove elements
    extensions.select! { |ext| ext.is_a? FooExtension }

    # or simply replace the whole Array
    self.extensions = [FooExtension.new]
  end
end
```

## Included extensions

These extensions are distributed with Blueprinter. Simply add them to your configuration.

### Field Order

Control the order of fields in your output. See [Fields API](../api/fields.md) for more information about the block parameters.

```ruby
extensions << Blueprinter::Extensions::FieldOrder.new { |a, b| a.name <=> b.name }
```

### MultiJson

The MultiJson extension switches Blueprinter from Ruby's built-in JSON library to the [multi_json](https://rubygems.org/gems/multi_json) gem. Just install the `multi_json` gem, your serialization library of choice, and enable the extension.

```ruby
extensions << Blueprinter::Extensions::MultiJson.new

# Any options you pass will be forwarded to MultiJson.dump
extensions << Blueprinter::Extensions::MultiJson.new(pretty: true)

# You can also pass MultiJson.dump options during render
WidgetBlueprint.render(widget, multi_json: { pretty: true }).to_json
```

If `multi_json` doesn't support your preferred JSON library, you can use Blueprinter's [around_result](../api/extensions.md#around_result) extension hook to render JSON however you like.

### OpenTelemetry

Enable the OpenTelemetry extension to see what's happening while you render your blueprints. One outer `blueprinter.render` span will nest various `blueprinter.object` and `blueprinter.collection` spans. Each span will include the blueprint/view name that triggered it.

Extension hooks will be wrapped in `blueprinter.extension` spans and annotated with the current extension and hook name.

```ruby
extensions << Blueprinter::Extensions::OpenTelemetry.new("my-tracer-name")
```

### ViewOption

The ViewOption extension uses the [around_result](../api/extensions.md#around_result) extension hook to add a `view` option to `render`, `render_object`, and `render_collection`. It allows V1-compatible rendering of views.

```ruby
extensions << Blueprinter::Extensions::ViewOption.new
```

Now you can render a view either way:

```ruby
# V2 style
MyBlueprint[:foo].render(obj)
# or V1 style
MyBlueprint.render(obj, view: :foo)
```

## Gem extensions

_Have an extension you'd like to share? Let us know and we may add it to the list!_

### blueprinter-activerecord

[blueprinter-activerecord](https://github.com/procore-oss/blueprinter-activerecord) is an official extension from the Blueprinter team providing ActiveRecord integration, including automatic preloading of associations based on your Blueprint definitions.
