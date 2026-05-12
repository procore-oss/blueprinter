# Breaking DSL Changes

At a quick glance the DSL looks nearly identical, but don't be fooled! See the docs of `Blueprinter::V2::DSL` for complete documentation of all new features.

### Association syntax

Associations must declare whether they're single objects or collections of objects. Also, the `blueprint` and `view` options are gone.

```ruby
# A single object
association :category, CategoryBlueprint
association :category, CategoryBlueprint[:my_view]

# A collection (Enumerable) of objects
association :parts, [PartBlueprint]
association :parts, [PartBlueprint[:my_view]]
```

If you're referencing the current view, such as in a recursive association, use `self`:

```ruby
view :with_child do
  association :child, self
end
```

If you're referencing a *different view in the current Blueprint*, you must wrap it in a Proc:

```ruby
class MyBlueprint < ApplicationBlueprint
  association :child, -> { MyBlueprint[:child_view] }
  association :children, [-> { MyBlueprint[:child_view] }]

  view :child_view do
    # ...
  end
end
```

If you're referencing the *same view name in a different Blueprint*, you may use `view_name`:

```ruby
view :extended do
  association :category, CategoryBlueprint[view_name]
end
```

### Second arg in field blocks

If you're using the *second* argument in your field/association blocks, it's no longer the render options. It's now a `Blueprinter::V2::Context::Field`
object, which contains the render options along with a lot more.

You can update your block in a single line:

```ruby
field :description do |object, ctx|
  options = ctx.options
  # ...
end
```

### Including a view

If you're including a view in another view, replace `include_view` with `use`.

```ruby
view :my_view do
  use :other_view
  # ...
end
```

This change may look superfluous, but it's the result of a cool new feature: [partials](../new/partials.md).

### Transformers

Transforming a Blueprint's output can be done using the `around_blueprint` extension hook. (See `Blueprinter::Extension` for full Extension API docs).

However, the `LegacyTransformer` extension offers compatibility with legacy/V1 transformer classes:

```ruby
extensions << Blueprinter::Extensions::LegacyTransformer.new(MyTransformer)
```

### `identifier`

Blueprinter Legacy/V1 had a special DSL method called `identifier`. It would accept the name of your primary key field,
add it to every view, and create a special view called `identifier` that contained only that field. It defaulted to `id`.

V2 does not include this very opinionated functionality, but you can easily replicate it in your base Blueprint:

```ruby
class ApplicationBlueprint < Blueprinter::Extension
  # The id field will be added to all Blueprints and views
  field :id

  # All Blueprints will get an identifier view, and it will only ever contain id
  view :identifier, empty: true do
    field :id
  end
end
```
