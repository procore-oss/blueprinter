# Breaking Reflection Changes

V2's reflection API is backwards compatible with the exception of renamed fields. This is a result of [a change in the DSL](../compatible/field-name-option.md).

In legacy/V1, here's how you would define and reflect on such a field:

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

In V2 it looks like this:

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
