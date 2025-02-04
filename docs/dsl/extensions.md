# Extensions

Blueprinter has a powerful extension system with hooks for every step of the serialization lifecycle. Some are included with Blueprinter, others are available as gems, and you can easily write your own using the [Extension API](../api/extensions.md).

## Using extensions

Extensions can be added to your `ApplicationBlueprint` or any other blueprint, view, or partial. They're inherited from parent classes and views, but can be overridden.

```ruby
class MyBlueprint < ApplicationBlueprint
  extensions << FooExtension.new
  extensions << BarExtension.new

  view :minimal do
    # extensions is a simple Array, so you can add or remove elements
    extensions.reject! { |ext| ext.is_a? BarExtension }

    # or simply replace the whole Array
    self.extensions = [FooExtension.new]
  end
end
```

## Included extensions

These extensions are distributed with Blueprinter. Simply add them to your configuration.

### Field Order

Control the order of fields in your output. See the `Field`, `ObjectField`, and `Collection` structs in [rubydoc.info/gems/blueprinter](https://www.rubydoc.info/gems/blueprinter) for more information about the block parameters.

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
WidgetBlueprint.render(widget, multi_json: { pretty: true })
```

If `multi_json` doesn't support your preferred JSON library, you can use Blueprinter's [json extension hook](../api/extensions.md#json) to render JSON however you like.

## Gem extensions

_Have an extension you'd like to share? Let us know and we may add it to the list!_

### blueprinter-activerecord

[blueprinter-activerecord](https://github.com/procore-oss/blueprinter-activerecord) is an official extension from the Blueprinter team providing ActiveRecord integration, including automatic preloading of associations based on your Blueprint definitions.
