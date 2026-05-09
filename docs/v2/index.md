# Changes in V2

While Blueprinter V2 is recognizably *Blueprinter*, there are several breaking changes. Some of them will require code changes while others
can be made backwards-compatible using bundled extensions.

```ruby
# Can you spot the differences?
class WidgetBlueprint < ApplicationBlueprint
  field :name
  field(:desc) { |widget| widget.description[0..100] }
  association :category, CategoryBlueprint

  view :extended do
    field :desc, source: :description
    association :subcategory, CategoryBlueprint[:subcategory]
    association :parts, [PartBlueprint]
  end
end
```

## Interoperability

The initial release of V2 is included *alongside* legacy/V1 code, allowing you to migrate your codebase slowly. V2 Blueprints can reference
legacy/V1 Blueprints in associations, and vice versa.

Eventually the legacy/V1 code will be removed, necessitating a complete switch to V2.
