# Field Modifier

This example alters the `source` of each field to use camel case.

```ruby
class SourceCamelizerExtension < Blueprinter::Extension
  def around_blueprint_init(ctx)
    ctx.fields.each do |field|
      field.source = field.source.to_s.camelize.to_sym
    end
    yield ctx
  end
end
```

This could also be done by overriding extraction in `around_field_value`/`around_object_value`/`around_collection_value`
hooks, but `around_blueprint_init` is probably faster. (It runs once per blueprint while `around_*_value` runs on every field).
