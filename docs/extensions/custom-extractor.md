# Custom Extractor

Blueprinter V2 automatically handles extraction from Hashes (symbol and string keys) and objects (`public_send`). If you have a more complex case, use the `around_field_value`, `around_object_value`, or   `around_collection_value` extension hooks.

The following example extension allows you to define extraction behavior for a given class:

```ruby
class CustomExtractor < Blueprinter::Extension
  def initialize(klass, &extractor)
    @klass = klass
    @extractor = extractor
  end
  
  # @param ctx [Blueprinter::V2::Context::Field]
  def around_field_value(ctx)
    if ctx.object.is_a? @klass
      # Use custom extraction
      @extractor.call(ctx.field.source, ctx.object)
    else
      # Let Blueprinter (or another extension) handle extraction
      yield ctx
    end
  end

  # Same behavior for associations
  alias around_object_value around_field_value
  alias around_collection_value around_field_value
end
```

Then add it to your base Blueprint, or to a specific Blueprint:

```ruby
class MyBlueprint < ApplicationBlueprint
  add CustomExtractor.new(MyClass) { |attr, object|
    # extract `attr` from `object` and return
  }
end
```
