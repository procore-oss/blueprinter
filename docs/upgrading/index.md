# Upgrading to API V2

You have two options when updating from the legacy/V1 API: [full update](#full-update) or [incremental update](#incremental-update).

Regardless which you choose, you'll need to familiarize yourself with the [new DSL](../dsl/index.md) and [API](../api/index.md). The rest of this section will focus on the differences between V1 and V2.

## Full update

Update `blueprinter` to 2.x. All of your blueprints will need updated to use the [new DSL](../dsl/index.md). If you're making use of extensions, custom extractors, or transformers, they'll also need updated to the [new API](../api/index.md).

## Incremental update

Larger applications may find it easier to update incrementally. Update `blueprinter` to 1.2.x, which contains both the legacy/V1 and V2 APIs. They can be used side-by-side.

```ruby
# A legacy/V1 blueprint
class WidgetBlueprint < Blueprinter::Blueprint
  field :name

  view :with_desc do
    field :description
  end

  view :with_category do
    # Using a V2 blueprint in a legacy/V1 blueprint
    association :category, blueprint: CategoryBlueprint, view: :extended
  end
end

# A V2 blueprint
class CategoryBlueprint < ApplicationBlueprint
  field :name

  view :extended do
    # Using a legacy/V1 blueprint in a V2 blueprint
    collection :widgets, WidgetBlueprint[:with_desc]
  end
end
```
