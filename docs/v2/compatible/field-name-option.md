# Field name option

In Blueprinter Legacy/V1, when a field's serialized name differs from the source name you represent it like this:

```ruby
# V1: Here's a field called "description". It pulls from "desc".
field :desc, name: :description
```

To allow this to continue working, enable the `LegacyRenameField` extension:

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  extensions << Blueprinter::Extensions::LegacyRenameField.new
end
```

## V2 style

Since Blueprinter is a serializer, the DSL should describe the serialized result, not the source object. V2 reads much more naturally:

```ruby
# V2: Here's a field called "description". It pulls from "desc".
field :description, source: :desc
```
