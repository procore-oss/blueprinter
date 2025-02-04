# Configuration

Blueprinter V2 has no concept of global configruation like V1's `Blueprinter.configure`. Instead, blueprints and views inherit configuration from their parent classes. By putting your "global" configuration into `ApplicationBlueprint`, all your application's blueprints and views will inherit it.

```ruby
class ApplicationBlueprint < Blueprinter::Blueprint
  options[:exclude_if_nil] = true
  extensions << MyExtension.new
end
```

Read more about [options](../dsl/options.md) and [extensions](../dsl/extensions.md).

## Overrides

Child classes, [views](../dsl/views.md), and [partials](../dsl/partials.md) can override their inherited configuration.

```ruby
class MyBlueprint < ApplicationBlueprint
  options[:exclude_if_nil] = false

  view :foo do
    options.clear
    extensions.clear
  end
end
```
