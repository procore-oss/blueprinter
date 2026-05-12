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

Of course this could also be done by passing a `source` to each field definition:

```ruby
field :foo_bar, source: :fooBar
```
