# Blueprinter

> [!WARNING]
This is a WIP for API V2!

Blueprinter is a JSON serializer for your business objects. It is designed to be simple, flexible, and performant.

Upgrading from 1.x? [Read the upgrade guide!](./upgrading/index.md)

### Installation

```bash
bundle add blueprinter
```

See [rubydoc.info/gems/blueprinter](https://www.rubydoc.info/gems/blueprinter) for API documentation.

### Basic Usage

```ruby
class WidgetBlueprint < ApplicationBlueprint
  field :name
  association :category, CategoryBlueprint
  association :parts, [PartBlueprint]

  view :extended do
    field :description
    association :manufacturer, CompanyBlueprint
    association :vendors, [CompanyBlueprint]
  end
end

# Render the default view to JSON
WidgetBlueprint.render(widget).to_json

# Render the extended view to a Hash
WidgetBlueprint[:extended].render(widget).to_hash
```
