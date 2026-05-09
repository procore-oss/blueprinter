# Camelize Fields

This example alters the `source` of each field to use camel case, leaving the serialized name as-is.

```ruby
class CamelizedSourceExtension < Blueprinter::Extension
  def around_blueprint_init(ctx)
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
