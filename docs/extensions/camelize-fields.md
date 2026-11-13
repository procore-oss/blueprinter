# Camelize Fields

This example alters the `source` of each field to use camel case, leaving the serialized name as-is.

`around_blueprint_init` runs once, when the Blueprint class is evaluated, so this costs nothing per render.

```ruby
class CamelizedSourceExtension < Blueprinter::Extension
  def initialize
    around_blueprint_init :camelize_fields
  end
  
  def camelize_fields(ctx)
    ctx.fields.each do |field|
      field.source = field.source.to_s.camelize(:lower).to_sym
    end
    yield ctx
  end
end
```

It's the equivalent of doing this for every field:

```ruby
field :foo_bar, source: :fooBar
```
