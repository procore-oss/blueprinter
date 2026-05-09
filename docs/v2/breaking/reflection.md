# Breaking Reflection Changes

> [!NOTE]
Most applications don't use reflection and can skip this section.

V2's reflection API is backwards compatible with the exception of renamed fields. This is a result of [a change in the DSL](../compatible/field-name-option.md).

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
class MyBlueprint < Blueprinter::Base
  # A field named "desc" that pulls from "description"
  field :desc, source: :description
end

field = MyBlueprint.reflections[:default].fields[:desc]
puts field.name   # name of serialized field
# => :desc
puts field.source # name of field's source
# => :description
```
