# Reflection

Blueprints may be reflected on to inspect their views, fields, and options. This is useful for building [extensions](./extensions.md), and possibly even for some applications.

We will use the following blueprint in the examples below:

```ruby
class WidgetBlueprint < ApplicationBlueprint
  field :name
  field :description, exclude_if_empty: true
  object :category, CategoryBlueprint
  collection :parts, PartBlueprint

  view :extended do
    object :manufacturer, CompanyBlueprint[:full]

    view :with_price do
      field :price
    end
  end
end
```

## Blueprint & view names

```ruby
WidgetBlueprint.blueprint_name
=> "WidgetBlueprint"

WidgetBlueprint.view_name
=> :default

WidgetBlueprint[:extended].blueprint_name
=> "WidgetBlueprint.extended"

WidgetBlueprint[:extended].view_name
=> :extended

WidgetBlueprint["extended.with_price"].blueprint_name
=> "WidgetBlueprint.extended.with_price"

WidgetBlueprint["extended.with_price"].view_name
=> :"extended.with_price"
```

## Blueprint & view options

```ruby
WidgetBlueprint.options
=> {exclude_if_nil: true}

WidgetBlueprint[:extended].options
=> {exclude_if_nil: true, exclude_if_empty: true}
```

## Views

Here, `:default` refers to the top level of the blueprint.

```ruby
WidgetBlueprint.reflections.keys
=> [:default, :extended, :"extended.with_price"]
```

You can also reflect directly on a view.

```ruby
WidgetBlueprint[:extended].reflections.keys
=> [:default, :with_price]
```

**Notice that the names are relative**: `:default` now refers to the `:extended` view, since we called `.reflections` on `:extended`. The prefix is also gone from the nested `:with_price` view.

## Fields

```ruby
view = WidgetBlueprint.reflections[:default]

# Regular fields
view.fields.keys
=> [:name, :description]

# Object fields
view.objects.keys
=> [:category]

# Collection fields
view.collections.keys
=> [:parts]

# All fields in the order they were defined
view.ordered
# returns an array of field objects
```

## Field metadata

```ruby
view = WidgetBlueprint.reflections[:default]
field = view.fields[:description]

field.name
=> :description

field.from
=> :description # the :from option in the DSL

field.value_proc
=> nil # the block you passed to the field, if any

field.options # all other options passed to the field
=> { exclude_if_empty: true }
```

Object and collection fields have the same metadata as regular fields, plus a `blueprint` attribute:

```ruby
view = WidgetBlueprint.reflections[:default]
field = view.collections[:parts]

# it returns the Blueprint class, so you can continue reflecting
field.blueprint
=> PartBlueprint

field.blueprint.reflections[:default].fields
=> # array of fields on the default view of PartBlueprint
```

If you used a view in an object or collection field, you can reflect on that view just like a blueprint:

```ruby
view = WidgetBlueprint.reflections[:extended]
field = view.objects[:manufacturer]

field.blueprint.to_s
=> "CompanyBlueprint.full"

# Remember, we're reflecting ON the :full view, so the name is relative!
field.blueprint.reflections[:default].fields
=> # array of fields on the :full view of CompanyBlueprint
```
