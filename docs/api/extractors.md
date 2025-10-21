# Extractors

Extractors are [extensions](./extensions.md#extract_value) that pull field values from the objects you're serializing. The default extraction logic is smart enough for most use cases, but you can create custom extractors if needed. (Note that passing a block to a field completely [bypasses extractors](../dsl/fields.md#extracting-field-values).)

## Default Extractor

The default extractor is a built-in extension. If `context.object` is a Hash, it tries symbol, then string keys. Otherwise, it calls `public_send` on the object.

```ruby
class Blueprinter::Extensions::Core::Extractor < Blueprinter::Extension
  def extract_value(ctx)
    if ctx.object.is_a? Hash
      ctx.object[ctx.field.from] || ctx.object[ctx.field.from_str]
    else
      ctx.object.public_send(ctx.field.from)
    end
  end
end
```

## Custom Extractors

Your [extract_value](./extensions.md#extract_value) hook will be passed a [Field context object](./context-objects.md#field-context).

```ruby
class WeirdObjectExtractor < Blueprinter::Extension
  def extract_value(ctx)
    # my extraction logic
  end
end
```

There are several ways to use your extractor:

* Add it to your blueprint(s) or view(s) like any other [extension](../dsl/extensions.md).
* Add it to specific fields using the [extractor option](../dsl/options.md#extractor).
