# Views

Blueprints can define views to provide different representations of the data. A view inherits everything from its parent but is free to override as needed. In addition to [fields](./fields.md), views can define [options](./options.md), [partials](./partials.md), [formatters](./formatters.md), [extensions](./extensions.md), and [nested views](#nesting-views).

```ruby
class WidgetBlueprint < ApplicationBlueprint
  field :name
  object :category, CategoryBlueprint

  # The "with_parts" view inherits from "default" and adds a collection of parts
  view :with_parts do
    collection :parts, PartBlueprint
  end

  # Views can include other views
  view :full do
    use :with_parts
    field :description
  end
end
```

At the top level of every Blueprint is an implicit view called `default`. The default view is used when no other is specified. All other views in the Blueprint inherit from it.

### Nesting views

You can nest views within views, allowing for a hierarchy of inheritance.

```ruby
class WidgetBlueprint < ApplicationBlueprint
  field :name
  object :category, CategoryBlueprint

  view :extended do
    field :description
    collection :parts, PartBlueprint

    # The "extended.with_price" view adds a price field
    view :with_price do
      field :price
    end
  end
```

### Excluding fields

Views can exclude select fields from parents, views they've included, or from [partials](./partials.md).

```ruby
class WidgetBlueprint < ApplicationBlueprint
  fields :name, :description, :price

  view :minimal do
    exclude :description, :price
  end
end
```

You can exclude and and all parent fields by creating an empty view:

```ruby
class WidgetBlueprint < ApplicationBlueprint
  fields :name, :description, :price

  view :minimal, empty: true do
    field :the_only_field
  end
end
```

### Referencing views

When defining an association, you can choose a view from its blueprint:

```ruby
object :widget, WidgetBlueprint[:extended]
```

Nested views can be accessed with a dot syntax or a nested Hash syntax.

```ruby
collection :widgets, WidgetBlueprint["extended.with_price"]
collection :widgets, WidgetBlueprint[:extended][:with_price]
```

### Inheriting from views

You can inherit from another blueprint, or from one of its views:

```ruby
class WidgetBlueprint < ApplicationBlueprint[:with_timestamps]
  # ...
end
```
