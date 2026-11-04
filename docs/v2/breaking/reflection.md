# Breaking Reflection Changes

## View reflection

V2's view reflection API is backwards compatible with the exception of the shorter `view?` form.

```ruby
MyBlueprint.view? :foo            # V1 only
MyBlueprint.reflections.key? :foo # V1 and V2
```

## Field reflection

V2's field reflection API is backwards compatible with the exception of renamed fields. This is a result of [a change in the DSL](../compatible/field-name-option.md).

### V1 style

```ruby
class MyBlueprint < Blueprinter::Base
  # A field named "desc" that pulls from "description"
  field :description, name: :desc
end

field = MyBlueprint.reflections[:default].fields[:desc]
puts field.display_name # name of serialized field
# => :desc
puts field.name         # name of field's source
# => :description
```

### V2 style

```ruby
class MyBlueprint < Blueprinter::V2::Base
  # A field named "desc" that pulls from "description"
  field :desc, source: :description
end

field = MyBlueprint.reflections[:default].fields[:desc]
puts field.name   # name of serialized field
# => :desc
puts field.source # name of field's source
# => :description
```
