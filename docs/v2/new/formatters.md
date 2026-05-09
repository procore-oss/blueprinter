# Formatters

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

If your formatter needs more information (field details, options passed to render, etc) use the `around_field_value`, `around_object_value`, and `around_collection_value` extension hooks. See `Blueprinter::Extension` for the full API, or get started with the [Extension Guide](../../extensions/index.md).
