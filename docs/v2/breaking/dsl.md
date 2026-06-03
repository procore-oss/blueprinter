# Breaking DSL Changes

At a quick glance the DSL looks nearly identical, but don't be fooled! See the docs of `Blueprinter::V2::DSL` for complete documentation of all new features.

### Association syntax

Associations in V2 are more concise while conveying more information.

```ruby
# A single object
association :category, CategoryBlueprint
association :category, CategoryBlueprint[:my_view]

# A collection (Enumerable) of objects
association :parts, [PartBlueprint]
association :parts, [PartBlueprint[:my_view]]
```

To dynamically reference the current view's name, use `view_name` or `view_path`:

```ruby
view :extended do
  # ...

  view :plus do
    # Looks for a view named 'plus'
    association :category, CategoryBlueprint[view_name]

    # Looks for a nested view named 'extended.plus'
    association :category, CategoryBlueprint[view_path]
  end
end
```

### Second arg in field blocks

If you're using the **second** argument in your field/association blocks, it's no longer the render options. It's now a `Blueprinter::V2::Context::Field`
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
add Blueprinter::Extensions::LegacyTransformer.new(MyTransformer)
```

### `identifier`

You can easily replicate legacy/V1's `identifier` field and view in your base Blueprint:

```ruby
class ApplicationBlueprint < Blueprinter::Extension
  # The id field will be added to all Blueprints and views
  field :id

  # All Blueprints will get an identifier view, and it will only ever contain id
  view :identifier do
    exclude fields: true
    field :id
  end
end
```
