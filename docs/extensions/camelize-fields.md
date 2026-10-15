# Camelize Fields

This example alters the `source` of each field to use camel case, leaving the serialized name as-is.

```ruby
class CamelizedSourceExtension < Blueprinter::Extension
  def initialize
    around_blueprint_init :camelize_fields
  end
  
  def camelize_fields(ctx)
    ctx.fields.each do |field|
      field.source = field.source_str.camelize(:lower).to_sym
    end
    yield ctx
  end
end
```

It's the equivalent of doing this for every field:

```ruby
field :foo_bar, source: :fooBar
```
