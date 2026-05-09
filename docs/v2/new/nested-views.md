# Nested views

Because [views in V2 are subclasses](./views-are-blueprints.md), you can define views inside of views. This allows you to mix and match
inheritence (views) with composition (`use`/`use!`).

Each view below inherits from its parent, which inherits from *its* parent, all the way up to `ApplicationBlueprint` and `Blueprinter::V2::Base`.

```ruby
class MyBlueprint < ApplicationBlueprint
  fields :name, :description

  view :extended do
    association :category, CategoryBlueprint

    view :with_foo do
      association :foo, FooBlueprint
    end

    view :with_bar do
      association :bar, BarBlueprint
    end
  end
end
```

You can render nested views using dot syntax:

```ruby
MyBlueprint["extended.with_foo"].render(widget).to_json
```

or nested Hash syntax:

```ruby
MyBlueprint[:extended][:with_bar].render(widget).to_json
```
