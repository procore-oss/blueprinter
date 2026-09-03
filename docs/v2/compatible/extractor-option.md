# Extractor option

V2 does not have a specific "extractor" concept, but the `LegacyOptions` extension allows your existing extractors to continue working.

```ruby
field :foo, extractor: MyExtractor
```

## V2 style

In V2 you can override Blueprinter's field extraction using field blocks or the `around_field_value`, `around_object_value`, and `around_collection_value` extension hooks.

```ruby
class MyExtractorExtension < Blueprinter::Extension
  # @param ctx [Blueprinter::V2::Context::Field]
  def extract(ctx)
    # Instead of yielding to get the field value, extract and return it here
    field_source = ctx.field.source
    object = ctx.object
    # ...
  end
  
  alias around_field_value extract
  alias around_object_value extract
  alias around_collection_value extract
end
```
