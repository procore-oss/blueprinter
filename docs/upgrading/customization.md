# Customization

## Formatting

Blueprinter V2 has a more generic approach to formatting, allowing any type of value to have formatting applied. [Learn more](../dsl/formatters.md).

```ruby
format(Date) { |date| date.iso8601 }
```

## Custom extractors

Extractors have a simplified API. [Learn more](../api/extractors.md).

## Transformers

Blueprinter V2's [extension hooks](../api/extensions.md) offer many ways to transform your inputs and outputs. The [blueprint_output](../api/extensions.md#blueprint_output) hook offers equivalent functionality to Legacy/V1 transformers.
