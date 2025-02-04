# Fields

## Identifier field and view

Blueprinter Legacy/V1 had a special feature for an `id` field and `identifier` view. Blueprinter V2 does not have this concept, but you can simulate it in your `ApplicationBlueprint`.

```ruby
class ApplicationBlueprint < Blueprinter::Blueprint
  # Every Blueprint that inherits from ApplicationBlueprint will have this field
  field :id

  # Every Blueprint that inherits from ApplicationBlueprint will have this view,
  # and it will only have the `id` field
  view :identifier, empty: true do
    field :id
  end
end
```

## Renaming fields

In Blueprinter Legacy/V1, you could rename fields using the `name` option. Blueprinter V2 swaps the order and uses `from`. We believe this makes your blueprints more readable.

In the following examples, both blueprints are populating the output field *description* from a source attribute named *desc*.

```ruby
# Legacy/V1
field :desc, name: :description

# V2
field :description, from: :desc
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

Blueprinter Legacy/V1 offered two options for ordering fields: `:name_asc` (default), and `:definition` (order they were defined in). Blueprinter V2 defaults to the order of definition. You can define a different order using the [blueprint_fields](../api/extensions.md#blueprint_fields) extension hook or the built-in [FieldOrder](../dsl/extensions.md#field-order) extension.

The following replicates Legacy/V1's default field order using the built-in [FieldOrder](../dsl/extensions.md#field-order) extension.

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
