# Upgrading to API V2

At first glance V2 looks very similar to V1. While this is generally true for the Blueprinter DSL, there are major differences when it comes to configuration and customizations like extractors, transformers, formatters, and extensions.

To help ease the transition, V2 can be used alongside legacy/V1. V2 Blueprints can reference legacy/V1 Blueprints in their associations and vice versa.

```ruby
# Not much difference in a basic V2 Blueprint
class WidgetBlueprint < ApplicationBlueprint
  field :name
  field(:desc) { |widget| widget.description }
  association :category, CategoryBlueprint

  view :extended do
    association :subcategory, CategoryBlueprint
  end
end
```
