# Customization

## Formatters

Blueprinter V2 has a more generic approach to formatting, allowing any type of field value to have its own formatter applied:

```ruby
class MyBlueprint < ApplicationBlueprint
  format(Date) { |date| date.iso8601 }
  format TrueClass, :boolean_str
  format FalseClass, :boolean_str

  def boolean_str(bool)
    bool ? "Y" : "N"
  end
end
```

The `around_field_value`, `around_object_value`, and `around_collection_value` extension hooks can also be used.

## Custom extractors

V2 supports custom extraction through the `around_field_value`, `around_object_value`, and `around_collection_value` extension hooks.

By not yielding, the following extension is responsible for extracting the value itself:

```ruby
class MyExtension < Blueprinter::Extension
  def around_field_value(ctx)
    ctx.object.public_send(ctx.field.source)
  end
end
```

See the documentation for `Blueprinter::Extension` for more info.

## Transformers

V2 supports transforming Blueprint output using the `around_serialize_object` and `around_serialize_collection` extension hooks.

```ruby
class MyExtension < Blueprinter::Extension
  def around_serialize_object(ctx)
    hash = yield ctx
    modify hash
  end
  
  def around_serialize_collection(ctx)
    hashes = yield ctx
    hashes.each { |hash| modify hash }
  end
end
```

See the documentation for `Blueprinter::Extension` for more info.
