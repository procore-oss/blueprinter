# Configuration

Blueprinter V2 has no concept of global configruation like V1's `Blueprinter.configure`. Instead, blueprints and views inherit configuration from their parent classes. By putting your "global" configuration into `ApplicationBlueprint`, all your application's blueprints and views will inherit it.

```ruby
class ApplicationBlueprint < Blueprinter::Blueprint
  options[:exclude_if_nil] = true
  options[:extractor] = MyExtractor
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

## Date/time formatting

Blueprinter V2 has a more generic approach to formatting, allowing any type of value to have formatting applied. [Learn more](../dsl/formatters.md).

## Custom extractors

Extractors have an updated API. [Learn more](../api/extractors.md).

## Transformers

There is no direct equivalent to V1's transformers. Instead, use [formatters](../dsl/formatters.md) or one of the new [extension hooks](../api/extensions.md).
