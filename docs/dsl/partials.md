# Partials

Partials allow you to compose views from reusable components. Just like views, partials can define [fields](./fields.md), [options](./options.md), [views](./views.md), other [partials](./partials.md), [formatters](./formatters.md), and [extensions](./extensions.md).

```ruby
class WidgetBlueprint < ApplicationBlueprint
  field :name

  view :foo do
    use :associations
    field :foo
  end

  view :bar do
    use :associations, :description
    field :bar
  end

  partial :associations do
    object :category, CategoryBlueprint
    collection :parts, PartBlueprint
  end

  partial :description do
    field :description
  end
end
```

There are two ways of including partials: [appending with 'use'](#append-with-use) and [inserting with 'use!'](#inserting-with-use) (see [examples](#examples-of-use-and-use)).

### Append with 'use'

Partials are _appended_ to your view, giving them the opportunity to override your view's fields, options, etc. Precedence (highest to lowest) is:

1. Definitions in the partial
2. Definitions in the view
3. Definitions inherited from the blueprint/parent views

### Insert with 'use!'

Partials are embedded immediately, _on that line_, allowing subsequent lines to override the partial. Precedence (highest to lowest) is:

1. Definitions in the view _after_ `use!`
2. Definitions in the partial
3. Definitions in the view _before_ `use!`
4. Definitions inherited from the blueprint/parent views

### Examples of 'use' and 'use!'

```ruby
partial :no_empty_fields do
  options[:field_if] = :og_field_logic
  # other stuff
end

# :foo appends the partial, so it overrides the view's field_if
view :foo do
  use :no_empty_fields
  options[:field_if] = :other_field_logic
end

# :bar inserts the partial, but the next line overrides the partial's field_if
view :bar do
  use! :no_empty_fields
  options[:field_if] = :other_field_logic
end
```
