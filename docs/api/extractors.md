# Extractors

Extractors pull values from the objects you're serializing. The default extractor is smart enough for most use cases, but you can create custom extractors as needed. (Note that passing a block to a field completely [bypasses extractors](../dsl/fields.md#extracting-field-values-from-objects).)

## Default Extractor

If `context.object` is a Hash, it tries symbol then string keys. Otherwise, it calls `public_send` on the object.

```ruby
class Blueprinter::Extractor
  # For regular fields
  def field(ctx)
    if ctx.object.is_a? Hash
      ctx.object[ctx.field.from] || ctx.object[ctx.field.from_str]
    else
      ctx.object.public_send(ctx.field.from)
    end
  end

  # For object fields
  def object(ctx)
    field ctx
  end

  # For collection fields
  def collection(ctx)
    field ctx
  end
end
```

## Custom Extractors

Override the `field`, `object`, or `collection` methods as needed. They'll be passed a [context object](./context-objects.md) with the following fields populated: `blueprint`, `field`, `object`, `options`, `instances`, `store`.

Note that a new version of your extractor will be initialized for each render, so it's safe to store state inside.

```ruby
class WeirdObjectExtractor < Blueprinter::Extractor
  def object(ctx)
    weird_extraction_logic ctx
  end
end
```

To use your extractor, pass it to the [extractor option](../dsl/options.md#extractor) in your blueprint, view, or field.
