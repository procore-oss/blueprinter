# Blueprinter DSL

## Define your base class

Define an `ApplicationBlueprint` for your blueprints to inherit from. Any global configuration goes here: common [fields](./fields.md), [views](./views.md), [partials](./partials.md), [formatters](./formatters.md), [extensions](./extensions.md), and [options](./options.md).

```ruby
class ApplicationBlueprint < Blueprinter::Blueprint
  extensions << MyExtension.new
  options[:exclude_if_nil] = true
  field :id
end
```

## Define blueprints for your models

This blueprint inherits everything from `ApplicationBlueprint`, then adds a `name` field and two associations that will render using other blueprints.

```ruby
class WidgetBlueprint < ApplicationBlueprint
  field :name
  object :category, CategoryBlueprint
  collection :parts, PartBlueprint
end
```

There's a lot more you can do with the Blueprinter DSL. [Fields](./fields.md) are a good place to start!
