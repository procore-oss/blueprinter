# Fields

## `id` field and `identifier` view

Blueprinter Legacy/V1 included a default field called `id` and a view called `identifier`. Blueprinter V2 does not have these, but you can easily replicate them with `ApplicationBlueprint`.

```ruby
class ApplicationBlueprint < Blueprinter::Blueprint
  field :id

  view :identifier do
    field :id
  end
end
```

## Associations

Blueprinter Legacy/V1 figured out if associations were single items or arrays at runtime. Blueprinter V2 accounts for this in the DSL. Also, the `:blueprint` and `:view` options are gone.

```ruby
class WidgetBlueprint < ApplicationBlueprint
  field :name
  object :category, CategoryBlueprint
  collection :parts, PartBlueprint

  # specify a view
  object :manufacturer, CompanyBlueprint[:extended]
end
```

## Field order

Blueprinter Legacy/V1 offered two options for ordering fields: `:name_asc` (default), and `:definition` (order they were defined in). Blueprinter V2 defaults to the order of definition. You can define a different order using the [blueprint_fields extension hook](../api/extensions.md#blueprint_fields) or the built-in `FieldOrder` extension.

The following replicates Legacy/V1's default field order using the built-in `FieldOrder` extension.

```ruby
class ApplicationBlueprint < Blueprinter::Blueprint
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
