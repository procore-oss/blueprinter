# Fields & Associations

## Associations

Blueprinter Legacy/V1 figured out if associations were single objects or arrays at runtime. V2 requires you to declare it in the DSL.

You'll also notice that the `:blueprint` and `:view` options are gone.

```ruby
class WidgetBlueprint < ApplicationBlueprint
  # A single object
  association :category, CategoryBlueprint
  
  # A collection of objects
  association :parts, [PartBlueprint]

  # Using custom views
  association :category, CategoryBlueprint[:extended]
  association :parts, [PartBlueprint[:extended]]
end
```

## Renaming fields

In Blueprinter Legacy/V1, if a field's serialized name differed from the source name, you would represent it like this:

```ruby
# V1: Here's a field called "description". It pulls from "desc".
field :desc, name: :description
```

The above reads backwards. Blueprinter is a serializer, and the DSL should describe the serialized result, not the source
object. V2 reads much more naturally:

```ruby
# V2: Here's a field called "description". It pulls from "desc".
field :description, source: :desc
```

## Identifier field and view

Blueprinter Legacy/V1 had a special DSL method called `identifier`. It would accept the name of your primary key field,
add it to every view, and create a special view called `identifier` that contained only that field. It defaulted to `id`.

V2 does not include this very opinionated functionality, but you can easily replicate it:

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  # Every Blueprint that inherits from ApplicationBlueprint will have this field
  field :id

  # Every Blueprint that inherits from ApplicationBlueprint will have this view,
  # and it will only ever contain the `id` field
  view :identifier, empty: true do
    field :id
  end
end
```

## Field order

Blueprinter Legacy/V1 offered two options for ordering fields: `:name_asc` (default, alpha order with `id` first), and `:definition` (order they were defined in). Blueprinter V2 defaults to the order of definition.

You can define a different order using the `around_blueprint_init` extension hook or the built-in `FieldOrder` extension. The following replicates Legacy/V1's default field order:

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  extensions << Blueprinter::Extensions::FieldOrder.new do |a, b|
    if a.name == :id
      -1
    elsif b.name == :id
      1
    else
      a.name <=> b.name
    end
  end
end
```
